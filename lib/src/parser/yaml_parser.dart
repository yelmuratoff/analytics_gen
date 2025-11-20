import 'dart:io';

import 'package:yaml/yaml.dart';

import '../config/naming_strategy.dart';
import '../core/exceptions.dart';
import '../models/analytics_event.dart';
import '../util/event_naming.dart';
import 'parameter_parser.dart';

/// Parses YAML files containing analytics event definitions.
final class YamlParser {
  final String eventsPath;
  final void Function(String message)? log;
  final NamingStrategy naming;
  final List<String> contextFiles;
  final ParameterParser _parameterParser;

  YamlParser({
    required this.eventsPath,
    this.log,
    NamingStrategy? naming,
    this.contextFiles = const [],
  })  : naming = naming ?? const NamingStrategy(),
        _parameterParser = ParameterParser(naming ?? const NamingStrategy());

  /// Parses all YAML files in the events directory and returns a map of domains.
  Future<Map<String, AnalyticsDomain>> parseEvents() async {
    final domains = <String, AnalyticsDomain>{};
    final errors = <AnalyticsParseException>[];

    await for (final domain in loadAnalyticsDomains(
      eventsPath: eventsPath,
      log: log,
      naming: naming,
      contextFiles: contextFiles,
      onError: errors.add,
    )) {
      domains[domain.name] = domain;
    }

    _validateUniqueEventNames(domains, onError: errors.add);

    if (errors.isNotEmpty) {
      throw AnalyticsAggregateException(errors);
    }

    return domains;
  }

  /// Internal helper to load domains as a stream while allowing reuse in tests.
  static Stream<AnalyticsDomain> loadAnalyticsDomains({
    required String eventsPath,
    NamingStrategy? naming,
    void Function(String message)? log,
    List<String> contextFiles = const [],
    void Function(AnalyticsParseException)? onError,
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

    final futures = yamlFiles.map((file) async {
      // Skip context files
      // We normalize paths to ensure consistent comparison
      final normalizedPath = file.path.replaceAll('\\', '/');
      if (contextFiles.any((c) => normalizedPath.endsWith(c))) {
        return null;
      }

      final content = await file.readAsString();
      return _ParsedFile(file, loadYaml(content));
    });

    final results =
        (await Future.wait(futures)).whereType<_ParsedFile>().toList();

    final merged = <String, _DomainSource>{};
    for (final result in results) {
      final file = result.file;
      final parsed = result.yaml;

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

        try {
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
        } on AnalyticsParseException catch (e) {
          if (onError != null) {
            onError(e);
          } else {
            rethrow;
          }
        } catch (e) {
          // Wrap other errors
          final error = AnalyticsParseException(
            e.toString(),
            filePath: file.path,
          );
          if (onError != null) {
            onError(error);
          } else {
            throw error;
          }
        }
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

      try {
        final events = parser._parseEventsForDomain(
          domainName,
          eventsYaml,
          filePath: source.filePath,
          onError: onError,
        );
        yield AnalyticsDomain(
          name: domainName,
          events: events,
        );
      } on AnalyticsParseException catch (e) {
        if (onError != null) {
          onError(e);
        } else {
          rethrow;
        }
      }
    }
  }

  /// Parses events for a single domain
  List<AnalyticsEvent> _parseEventsForDomain(
    String domainName,
    YamlMap eventsYaml, {
    required String filePath,
    void Function(AnalyticsParseException)? onError,
  }) {
    final events = <AnalyticsEvent>[];

    final sortedEvents = eventsYaml.entries.toList()
      ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));

    for (final entry in sortedEvents) {
      final eventName = entry.key.toString();
      final value = entry.value;

      try {
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

        final meta = _parseMeta(eventData['meta'], filePath);

        final rawParameters = eventData['parameters'];
        if (rawParameters != null && rawParameters is! YamlMap) {
          throw AnalyticsParseException(
            'Parameters for event "$domainName.$eventName" in $filePath must be a map.',
            filePath: filePath,
          );
        }

        final parametersYaml = (rawParameters as YamlMap?) ?? YamlMap();
        final parameters = _parameterParser.parseParameters(
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
            meta: meta,
          ),
        );
      } on AnalyticsParseException catch (e) {
        if (onError != null) {
          onError(e);
        } else {
          rethrow;
        }
      } catch (e) {
        final error = AnalyticsParseException(
          e.toString(),
          filePath: filePath,
        );
        if (onError != null) {
          onError(error);
        } else {
          throw error;
        }
      }
    }

    return events;
  }

  Map<String, Object?> _parseMeta(dynamic metaYaml, String filePath) {
    if (metaYaml == null) return const {};
    if (metaYaml is! YamlMap) {
      throw AnalyticsParseException(
        'The "meta" field must be a map.',
        filePath: filePath,
      );
    }
    // Convert YamlMap to Map<String, Object?>
    return metaYaml.map((key, value) => MapEntry(key.toString(), value));
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
    final parser = ParameterParser(const NamingStrategy());
    return parser.parseParameters(
      parametersYaml,
      domainName: domainName,
      eventName: eventName,
      filePath: filePath,
    );
  }

  /// Ensures every resolved [AnalyticsEvent] identifier is unique across domains.
  void _validateUniqueEventNames(
    Map<String, AnalyticsDomain> domains, {
    void Function(AnalyticsParseException)? onError,
  }) {
    final seen = <String, String>{};

    for (final entry in domains.entries) {
      final domainName = entry.key;
      for (final event in entry.value.events) {
        try {
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
        } on AnalyticsParseException catch (e) {
          if (onError != null) {
            onError(e);
          } else {
            rethrow;
          }
        }
      }
    }
  }

  /// Parses all configured context files.
  /// Returns a map where the key is the context name (from the YAML root key)
  /// and the value is the list of parameters.
  Future<Map<String, List<AnalyticsParameter>>> parseContexts() async {
    final contexts = <String, List<AnalyticsParameter>>{};

    for (final filePath in contextFiles) {
      final file = File(filePath);
      if (!file.existsSync()) {
        log?.call('Context file not found: $filePath');
        continue;
      }

      final content = await file.readAsString();
      final yaml = loadYaml(content);

      if (yaml is! YamlMap) {
        throw AnalyticsParseException(
          'Context file $filePath must be a map.',
          filePath: filePath,
        );
      }

      // We expect a single root key which defines the context name
      // e.g. user: { ... }
      if (yaml.keys.length != 1) {
        throw AnalyticsParseException(
          'Context file $filePath must contain exactly one root key defining the context name.',
          filePath: filePath,
        );
      }

      final contextName = yaml.keys.first.toString();
      final propertiesYaml = yaml[contextName];

      if (propertiesYaml is! YamlMap) {
        throw AnalyticsParseException(
          'The "$contextName" key in $filePath must be a map of properties.',
          filePath: filePath,
        );
      }

      final parameters = _parameterParser.parseParameters(
        propertiesYaml,
        domainName: contextName,
        eventName: 'context', // Dummy
        filePath: filePath,
      );

      contexts[contextName] = parameters;
    }

    return contexts;
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

final class _ParsedFile {
  final File file;
  final dynamic yaml;

  _ParsedFile(this.file, this.yaml);
}
