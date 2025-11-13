import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import '../models/analytics_event.dart';

/// Parses YAML files containing analytics event definitions.
final class YamlParser {
  final String eventsPath;

  YamlParser({required this.eventsPath});

  /// Parses all YAML files in the events directory and returns a map of domains.
  Future<Map<String, AnalyticsDomain>> parseEvents() async {
    final eventsDir = Directory(eventsPath);

    if (!eventsDir.existsSync()) {
      print('Events directory not found at: $eventsPath');
      return {};
    }

    // Find all YAML files
    final yamlFiles = eventsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.yaml') || f.path.endsWith('.yml'))
        .toList();

    if (yamlFiles.isEmpty) {
      print('No YAML files found in: $eventsPath');
      return {};
    }

    print('Found ${yamlFiles.length} YAML file(s) in $eventsPath');

    // Parse and merge all YAML files
    final Map<String, dynamic> merged = {};
    for (final file in yamlFiles) {
      final content = await file.readAsString();
      final parsed = loadYaml(content);

      if (parsed is! YamlMap) {
        print('Warning: ${path.basename(file.path)} does not contain a YamlMap. Skipping.');
        continue;
      }

      // Check for duplicate domains
      for (final key in parsed.keys) {
        if (merged.containsKey(key)) {
          throw StateError(
            'Duplicate domain "$key" found in multiple files. '
            'Each domain must be defined in only one file.',
          );
        }
        merged[key] = parsed[key];
      }
    }

    // Convert to domain models
    final domains = <String, AnalyticsDomain>{};
    for (final entry in merged.entries) {
      final domainName = entry.key.toString();
      final eventsYaml = entry.value as YamlMap;

      final events = _parseEventsForDomain(domainName, eventsYaml);
      domains[domainName] = AnalyticsDomain(
        name: domainName,
        events: events,
      );
    }

    return domains;
  }

  /// Parses events for a single domain
  List<AnalyticsEvent> _parseEventsForDomain(
    String domainName,
    YamlMap eventsYaml,
  ) {
    final events = <AnalyticsEvent>[];

    for (final entry in eventsYaml.entries) {
      final eventName = entry.key.toString();
      final eventData = entry.value as YamlMap;

      final description = eventData['description'] as String? ??
          'No description provided';
      final customEventName = eventData['event_name'] as String?;
      final parametersYaml = eventData['parameters'] as YamlMap? ?? YamlMap();

      final parameters = _parseParameters(parametersYaml);

      events.add(
        AnalyticsEvent(
          name: eventName,
          description: description,
          customEventName: customEventName,
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
