import 'dart:io';

import 'package:yaml/yaml.dart';

import '../core/exceptions.dart';
import '../config/naming_strategy.dart';
import '../models/analytics_event.dart';
import '../util/event_naming.dart';
import '../util/string_utils.dart';

/// Parses YAML files containing analytics event definitions.
final class YamlParser {
  final String eventsPath;
  final void Function(String message)? log;
  final NamingStrategy naming;

  YamlParser({
    required this.eventsPath,
    this.log,
    NamingStrategy? naming,
  }) : naming = naming ?? const NamingStrategy();

  /// Parses all YAML files in the events directory and returns a map of domains.
  Future<Map<String, AnalyticsDomain>> parseEvents() async {
    final domains = <String, AnalyticsDomain>{};
    await for (final domain in loadAnalyticsDomains(
      eventsPath: eventsPath,
      log: log,
      naming: naming,
    )) {
      domains[domain.name] = domain;
    }

    _validateUniqueEventNames(domains);

    return domains;
  }

  /// Internal helper to load domains as a stream while allowing reuse in tests.
  static Stream<AnalyticsDomain> loadAnalyticsDomains({
    required String eventsPath,
    NamingStrategy? naming,
    void Function(String message)? log,
  }) async* {
    final strategy = naming ?? const NamingStrategy();
    final eventsDir = Directory(eventsPath);

    if (!eventsDir.existsSync()) {
      log?.call('Events directory not found at: $eventsPath');
      return;
    }

    final yamlFiles = eventsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.yaml') || f.path.endsWith('.yml'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

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

      final sortedDomainKeys = parsed.keys.toList()
        ..sort((a, b) => a.toString().compareTo(b.toString()));

      for (final key in sortedDomainKeys) {
        final domainKey = key.toString();

        // Enforce snake_case, filesystem-safe domain names
        final isValidDomain = strategy.isValidDomain(domainKey);
        if (!isValidDomain) {
          throw AnalyticsParseException(
            'Domain "$domainKey" in ${file.path} violates the configured '
            'naming strategy. Update analytics_gen.naming.enforce_snake_case_domains '
            'or rename the domain.',
            filePath: file.path,
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

    final sortedDomains = merged.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in sortedDomains) {
      final domainName = entry.key.toString();
      final source = entry.value;
      final eventsYaml = source.yaml;

      final parser = YamlParser(
        eventsPath: eventsPath,
        log: log,
        naming: strategy,
      );
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

    final sortedEvents = eventsYaml.entries.toList()
      ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));

    for (final entry in sortedEvents) {
      final eventName = entry.key.toString();
      final value = entry.value;

      if (value is! YamlMap) {
        throw AnalyticsParseException(
          'Event "$domainName.$eventName" in $filePath must be a map.',
          filePath: filePath,
        );
      }

      final eventData = value;

      final description =
          eventData['description'] as String? ?? 'No description provided';
      final customEventName = eventData['event_name'] as String?;
      final identifier = eventData['identifier'] as String?;
      final deprecated = eventData['deprecated'] as bool? ?? false;
      final replacement = eventData['replacement'] as String?;

      final rawParameters = eventData['parameters'];
      if (rawParameters != null && rawParameters is! YamlMap) {
        throw AnalyticsParseException(
          'Parameters for event "$domainName.$eventName" in $filePath must be a map.',
          filePath: filePath,
        );
      }

      final parametersYaml = (rawParameters as YamlMap?) ?? YamlMap();
      final parameters = _parseParameters(
        parametersYaml,
        domainName: domainName,
        eventName: eventName,
        filePath: filePath,
      );

      events.add(
        AnalyticsEvent(
          name: eventName,
          description: description,
          identifier: identifier,
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
  List<AnalyticsParameter> _parseParameters(
    YamlMap parametersYaml, {
    required String domainName,
    required String eventName,
    required String filePath,
  }) {
    final parameters = <AnalyticsParameter>[];
    final seenRawNames = <String>{};
    final seenAnalyticsNames = <String>{};
    final camelNameToOriginal = <String, String>{};

    final sortedEntries = parametersYaml.entries.toList()
      ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));

    for (final entry in sortedEntries) {
      final rawName = entry.key.toString();
      if (!seenRawNames.add(rawName)) {
        throw AnalyticsParseException(
          'Duplicate parameter "$rawName" found in $domainName.$eventName.',
          filePath: filePath,
        );
      }

      final paramValue = entry.value;
      final identifierOverride =
          paramValue is YamlMap ? paramValue['identifier'] as String? : null;
      final wireNameOverride =
          paramValue is YamlMap ? paramValue['param_name'] as String? : null;

      final codeIdentifier = identifierOverride ?? rawName;
      final analyticsName = wireNameOverride ?? rawName;

      if (codeIdentifier.isEmpty) {
        throw AnalyticsParseException(
          'Parameter "$rawName" in $domainName.$eventName must declare a '
          'non-empty identifier.',
          filePath: filePath,
        );
      }

      if (!naming.isValidParameterIdentifier(codeIdentifier)) {
        throw AnalyticsParseException(
          'Parameter identifier "$codeIdentifier" in $domainName.$eventName '
          'violates the configured naming strategy. Update '
          'analytics_gen.naming.enforce_snake_case_parameters or define a '
          'different `identifier`.',
          filePath: filePath,
        );
      }

      if (!seenAnalyticsNames.add(analyticsName)) {
        throw AnalyticsParseException(
          'Duplicate analytics parameter "$analyticsName" found in '
          '$domainName.$eventName.',
          filePath: filePath,
        );
      }

      final camelParamName = StringUtils.toCamelCase(codeIdentifier);
      final existingParam = camelNameToOriginal[camelParamName];
      if (existingParam != null) {
        throw AnalyticsParseException(
          'Parameter identifier "$codeIdentifier" in $domainName.$eventName '
          'conflicts with "$existingParam" after camelCase normalization.',
          filePath: filePath,
        );
      }
      camelNameToOriginal[camelParamName] = codeIdentifier;

      String paramType;
      String? description;
      List<String>? allowedValues;

      if (paramValue is YamlMap) {
        // Complex parameter with 'type' and/or 'description'
        description = paramValue['description'] as String?;

        // Check if 'type' key exists explicitly
        if (paramValue.containsKey('type')) {
          paramType = paramValue['type'].toString();
        } else {
          // Fallback: Find type key (anything except 'description')
          final typeKey = paramValue.keys
              .where(
                (k) =>
                    k.toString() != 'description' &&
                    k.toString() != 'allowed_values' &&
                    k.toString() != 'identifier' &&
                    k.toString() != 'param_name',
              )
              .firstOrNull;
          paramType = typeKey?.toString() ?? 'dynamic';
        }

        final rawAllowed = paramValue['allowed_values'];
        if (rawAllowed != null) {
          if (rawAllowed is! YamlList) {
            throw AnalyticsParseException(
              'allowed_values for parameter "$rawName" must be a list.',
              filePath: filePath,
            );
          }
          allowedValues = rawAllowed.map((e) => e.toString()).toList();
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
          name: analyticsName,
          codeName: codeIdentifier,
          type: paramType,
          isNullable: isNullable,
          description: description,
          allowedValues: allowedValues,
        ),
      );
    }

    return parameters;
  }

  /// Public helper used by tests to exercise parameter parsing logic
  /// without traversing the full YAML loader pipeline.
  ///
  /// This is primarily used to simulate unusual keys that may be valid
  /// in a YamlMap (for example, keys that return the same `toString()`
  /// value) and ensure duplicate checks still work as intended.
  static List<AnalyticsParameter> parseParametersFromYaml(
    YamlMap parametersYaml, {
    required String domainName,
    required String eventName,
    required String filePath,
  }) {
    final parser = YamlParser(eventsPath: '.', log: null);
    return parser._parseParameters(
      parametersYaml,
      domainName: domainName,
      eventName: eventName,
      filePath: filePath,
    );
  }

  /// Ensures every resolved [AnalyticsEvent] identifier is unique across domains.
  void _validateUniqueEventNames(Map<String, AnalyticsDomain> domains) {
    final seen = <String, String>{};

    for (final entry in domains.entries) {
      final domainName = entry.key;
      for (final event in entry.value.events) {
        final actualIdentifier =
            EventNaming.resolveIdentifier(domainName, event, naming);
        final conflictDomain = seen[actualIdentifier];

        if (conflictDomain != null) {
          throw AnalyticsParseException(
            'Duplicate analytics event identifier "$actualIdentifier" found '
            'in domains "$conflictDomain" and "$domainName". '
            'Provide a custom `identifier` or update '
            '`analytics_gen.naming.identifier_template` to make identifiers unique.',
            filePath: null,
          );
        }

        seen[actualIdentifier] = domainName;
      }
    }
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
