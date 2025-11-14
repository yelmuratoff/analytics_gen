import 'dart:io';

import 'package:yaml/yaml.dart';

import '../models/analytics_event.dart';

/// Parses YAML files containing analytics event definitions.
final class YamlParser {
  final String eventsPath;
  final void Function(String message)? log;

  YamlParser({
    required this.eventsPath,
    this.log,
  });

  /// Parses all YAML files in the events directory and returns a map of domains.
  Future<Map<String, AnalyticsDomain>> parseEvents() async {
    final domains = <String, AnalyticsDomain>{};
    await for (final domain in loadAnalyticsDomains(
      eventsPath: eventsPath,
      log: log,
    )) {
      domains[domain.name] = domain;
    }

    return domains;
  }

  /// Internal helper to load domains as a stream while allowing reuse in tests.
  static Stream<AnalyticsDomain> loadAnalyticsDomains({
    required String eventsPath,
    void Function(String message)? log,
  }) async* {
    final eventsDir = Directory(eventsPath);

    if (!eventsDir.existsSync()) {
      log?.call('Events directory not found at: $eventsPath');
      return;
    }

    final yamlFiles = eventsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.yaml') || f.path.endsWith('.yml'))
        .toList();

    if (yamlFiles.isEmpty) {
      log?.call('No YAML files found in: $eventsPath');
      return;
    }

    log?.call('Found ${yamlFiles.length} YAML file(s) in $eventsPath');

    final merged = <String, _DomainSource>{};
    for (final file in yamlFiles) {
      final content = await file.readAsString();
      final parsed = loadYaml(content);

      if (parsed is! YamlMap) {
        log?.call(
          'Warning: ${file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : file.path} does not contain a YamlMap. Skipping.',
        );
        continue;
      }

      for (final key in parsed.keys) {
        final domainKey = key.toString();

        // Enforce snake_case, filesystem-safe domain names
        final isValidDomain = RegExp(r'^[a-z0-9_]+$').hasMatch(domainKey);
        if (!isValidDomain) {
          throw FormatException(
            'Domain "$domainKey" in ${file.path} must use snake_case '
            'with lowercase letters, digits and underscores only.',
          );
        }

        if (merged.containsKey(domainKey)) {
          throw StateError(
            'Duplicate domain "$domainKey" found in multiple files. '
            'Each domain must be defined in only one file.',
          );
        }
        final value = parsed[key];
        if (value is! YamlMap) {
          throw FormatException(
            'Domain "$domainKey" in ${file.path} must be a map of events.',
          );
        }
        merged[domainKey] = _DomainSource(
          filePath: file.path,
          yaml: value,
        );
      }
    }

    for (final entry in merged.entries) {
      final domainName = entry.key.toString();
      final source = entry.value;
      final eventsYaml = source.yaml;

      final parser = YamlParser(eventsPath: eventsPath, log: log);
      final events = parser._parseEventsForDomain(
        domainName,
        eventsYaml,
        filePath: source.filePath,
      );
      yield AnalyticsDomain(
        name: domainName,
        events: events,
      );
    }
  }

  /// Parses events for a single domain
  List<AnalyticsEvent> _parseEventsForDomain(
    String domainName,
    YamlMap eventsYaml, {
    required String filePath,
  }) {
    final events = <AnalyticsEvent>[];

    for (final entry in eventsYaml.entries) {
      final eventName = entry.key.toString();
      final value = entry.value;

      if (value is! YamlMap) {
        throw FormatException(
          'Event "$domainName.$eventName" in $filePath must be a map.',
        );
      }

      final eventData = value;

      final description = eventData['description'] as String? ??
          'No description provided';
      final customEventName = eventData['event_name'] as String?;
      final deprecated = eventData['deprecated'] as bool? ?? false;
      final replacement = eventData['replacement'] as String?;

      final rawParameters = eventData['parameters'];
      if (rawParameters != null && rawParameters is! YamlMap) {
        throw FormatException(
          'Parameters for event "$domainName.$eventName" in $filePath must be a map.',
        );
      }

      final parametersYaml = (rawParameters as YamlMap?) ?? YamlMap();
      final parameters = _parseParameters(parametersYaml);

      events.add(
        AnalyticsEvent(
          name: eventName,
          description: description,
          customEventName: customEventName,
          deprecated: deprecated,
          replacement: replacement,
          parameters: parameters,
        ),
      );
    }

    return events;
  }

  /// Parses parameters from YAML
  List<AnalyticsParameter> _parseParameters(YamlMap parametersYaml) {
    final parameters = <AnalyticsParameter>[];

    for (final entry in parametersYaml.entries) {
      final paramName = entry.key.toString();
      final paramValue = entry.value;

      String paramType;
      String? description;

      if (paramValue is YamlMap) {
        // Complex parameter with 'type' and/or 'description'
        description = paramValue['description'] as String?;

        // Check if 'type' key exists explicitly
        if (paramValue.containsKey('type')) {
          paramType = paramValue['type'].toString();
        } else {
          // Fallback: Find type key (anything except 'description')
          final typeKey = paramValue.keys
              .where((k) => k.toString() != 'description')
              .firstOrNull;
          paramType = typeKey?.toString() ?? 'dynamic';
        }
      } else {
        // Simple parameter (just type)
        paramType = paramValue.toString();
      }

      // Check if nullable
      final isNullable = paramType.endsWith('?');
      if (isNullable) {
        paramType = paramType.substring(0, paramType.length - 1);
      }

      parameters.add(
        AnalyticsParameter(
          name: paramName,
          type: paramType,
          isNullable: isNullable,
          description: description,
        ),
      );
    }

    return parameters;
  }
}

final class _DomainSource {
  final String filePath;
  final YamlMap yaml;

  _DomainSource({
    required this.filePath,
    required this.yaml,
  });
}
