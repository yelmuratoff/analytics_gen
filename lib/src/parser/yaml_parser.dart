import 'package:yaml/yaml.dart';

import '../config/naming_strategy.dart';
import '../core/exceptions.dart';
import '../models/analytics_event.dart';
import '../util/logger.dart';
import 'event_loader.dart';
import 'parameter_parser.dart';
import 'schema_validator.dart';

/// Parses YAML files containing analytics event definitions.
final class YamlParser {
  final Logger log;
  final NamingStrategy naming;
  final ParameterParser _parameterParser;
  final SchemaValidator _validator;

  YamlParser({
    this.log = const NoOpLogger(),
    NamingStrategy? naming,
    SchemaValidator? validator,
  })  : naming = naming ?? const NamingStrategy(),
        _parameterParser = ParameterParser(naming ?? const NamingStrategy()),
        _validator =
            validator ?? SchemaValidator(naming ?? const NamingStrategy());

  /// Parses the provided analytics sources and returns a map of domains.
  Future<Map<String, AnalyticsDomain>> parseEvents(
    List<AnalyticsSource> sources,
  ) async {
    final domains = <String, AnalyticsDomain>{};
    final errors = <AnalyticsParseException>[];

    await for (final domain in _parseSources(
      sources,
      log: log,
      naming: naming,
      onError: errors.add,
    )) {
      domains[domain.name] = domain;
    }

    _validator.validateUniqueEventNames(domains, onError: errors.add);

    if (errors.isNotEmpty) {
      throw AnalyticsAggregateException(errors);
    }

    return domains;
  }

  /// Internal helper to parse sources as a stream.
  Stream<AnalyticsDomain> _parseSources(
    List<AnalyticsSource> sources, {
    NamingStrategy? naming,
    Logger log = const NoOpLogger(),
    void Function(AnalyticsParseException)? onError,
  }) async* {
    final strategy = naming ?? const NamingStrategy();

    if (sources.isEmpty) {
      log.warning('No YAML sources provided for parsing');
      return;
    }

    final merged = <String, _DomainSource>{};
    for (final source in sources) {
      final YamlNode parsedNode;
      try {
        parsedNode = loadYamlNode(source.content);
      } catch (e) {
        final error = AnalyticsParseException(
          'Failed to parse YAML file: $e',
          filePath: source.filePath,
          innerError: e,
        );
        if (onError != null) {
          onError(error);
        } else {
          throw error;
        }
        continue;
      }

      if (parsedNode is! YamlMap) {
        // If the file is empty or contains only comments, loadYamlNode might return a YamlScalar with null value
        if (parsedNode is YamlScalar && parsedNode.value == null) {
          continue;
        }

        final error = AnalyticsParseException(
          'Root of the YAML file must be a map.',
          filePath: source.filePath,
          span: parsedNode.span,
        );
        if (onError != null) {
          onError(error);
        } else {
          throw error;
        }
        continue;
      }

      final parsedMap = parsedNode;
      final sortedDomainKeys = parsedMap.nodes.keys.toList()
        ..sort((a, b) => a.toString().compareTo(b.toString()));

      for (final keyNode in sortedDomainKeys) {
        final domainKey = keyNode.toString();
        final valueNode = parsedMap.nodes[keyNode];

        try {
          // Enforce snake_case, filesystem-safe domain names
          _validator.validateDomainName(domainKey, source.filePath);

          if (merged.containsKey(domainKey)) {
            throw StateError(
              'Duplicate domain "$domainKey" found in multiple files. '
              'Each domain must be defined in only one file.',
            );
          }

          if (valueNode is! YamlMap) {
            throw AnalyticsParseException(
              'Domain "$domainKey" must be a map of events.',
              filePath: source.filePath,
              span: valueNode?.span ?? keyNode.span,
            );
          }

          merged[domainKey] = _DomainSource(
            filePath: source.filePath,
            yaml: valueNode,
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
            filePath: source.filePath,
            innerError: e,
            span: (keyNode is YamlNode) ? keyNode.span : null,
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

    final sortedEvents = eventsYaml.nodes.entries.toList()
      ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));

    for (final entry in sortedEvents) {
      final keyNode = entry.key as YamlNode;
      final eventName = keyNode.toString();
      final valueNode = entry.value;

      try {
        // Strict Event Name Validation: Check for interpolation
        if (eventName.contains('{') || eventName.contains('}')) {
          throw AnalyticsParseException(
            'Event name "$eventName" contains interpolation characters "{}" or "{}". '
            'Dynamic event names are discouraged as they lead to high cardinality.',
            filePath: filePath,
            span: keyNode.span,
          );
        }

        if (valueNode is! YamlMap) {
          throw AnalyticsParseException(
            'Event "$domainName.$eventName" must be a map.',
            filePath: filePath,
            span: valueNode.span,
          );
        }

        final eventData = valueNode;

        final description =
            eventData['description'] as String? ?? 'No description provided';
        final customEventName = eventData['event_name'] as String?;
        final identifier = eventData['identifier'] as String?;
        final deprecated = eventData['deprecated'] as bool? ?? false;
        final replacement = eventData['replacement'] as String?;

        final metaNode = eventData.nodes['meta'];
        final meta = _parseMeta(metaNode, filePath);

        final rawParameters = eventData.nodes['parameters'];
        if (rawParameters != null && rawParameters is! YamlMap) {
          throw AnalyticsParseException(
            'Parameters for event "$domainName.$eventName" must be a map.',
            filePath: filePath,
            span: rawParameters.span,
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
          innerError: e,
          span: keyNode.span,
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

  Map<String, Object?> _parseMeta(YamlNode? metaNode, String filePath) {
    if (metaNode == null) return const {};
    if (metaNode is! YamlMap) {
      throw AnalyticsParseException(
        'The "meta" field must be a map.',
        filePath: filePath,
        span: metaNode.span,
      );
    }
    // Convert YamlMap to Map<String, Object?>
    return metaNode.map((key, value) => MapEntry(key.toString(), value));
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

  /// Parses all configured context files.
  /// Returns a map where the key is the context name (from the YAML root key)
  /// and the value is the list of parameters.
  Future<Map<String, List<AnalyticsParameter>>> parseContexts(
    List<AnalyticsSource> sources,
  ) async {
    final contexts = <String, List<AnalyticsParameter>>{};

    for (final source in sources) {
      final YamlNode parsedNode;
      try {
        parsedNode = loadYamlNode(source.content);
      } catch (e) {
        throw AnalyticsParseException(
          'Failed to parse YAML file: $e',
          filePath: source.filePath,
          innerError: e,
        );
      }

      if (parsedNode is! YamlMap) {
        throw AnalyticsParseException(
          'Context file must be a map.',
          filePath: source.filePath,
          span: parsedNode.span,
        );
      }

      final yaml = parsedNode;

      // We expect a single root key which defines the context name
      // e.g. user: { ... }
      if (yaml.keys.length != 1) {
        throw AnalyticsParseException(
          'Context file must contain exactly one root key defining the context name.',
          filePath: source.filePath,
          span: yaml.span,
        );
      }

      final contextNameNode = yaml.nodes.keys.first as YamlNode;
      final contextName = contextNameNode.toString();
      final propertiesNode = yaml.nodes[contextNameNode];

      if (propertiesNode is! YamlMap) {
        throw AnalyticsParseException(
          'The "$contextName" key must be a map of properties.',
          filePath: source.filePath,
          span: propertiesNode?.span ?? contextNameNode.span,
        );
      }

      final parameters = _parameterParser.parseParameters(
        propertiesNode,
        domainName: contextName,
        eventName: 'context', // Dummy
        filePath: source.filePath,
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
