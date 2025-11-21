import 'package:yaml/yaml.dart';

import '../config/naming_strategy.dart';
import '../core/exceptions.dart';
import '../models/analytics_event.dart';
import '../util/logger.dart';
import 'event_loader.dart';
import 'parameter_parser.dart';
import 'schema_validator.dart';

/// Parses YAML files containing analytics event definitions.
typedef LoadYamlNode = YamlNode Function(String,
    {dynamic sourceUrl, dynamic recover, dynamic errorListener});

/// YAML parser for analytics event definitions.
final class YamlParser {
  /// Creates a new YAML parser.
  YamlParser({
    this.log = const NoOpLogger(),
    NamingStrategy? naming,
    this.strictEventNames = true,
    SchemaValidator? validator,
    LoadYamlNode? loadYaml,
    void Function(String domainKey, YamlNode? valueNode)? domainHook,
  })  : naming = naming ?? const NamingStrategy(),
        _parameterParser = ParameterParser(naming ?? const NamingStrategy()),
        _validator = validator ??
            SchemaValidator(
              naming ?? const NamingStrategy(),
              strictEventNames: strictEventNames,
            ),
        _loadYamlNode = loadYaml ??
            ((String content,
                    {dynamic sourceUrl,
                    dynamic recover,
                    dynamic errorListener}) =>
                loadYamlNode(content,
                    sourceUrl: sourceUrl as Uri?,
                    recover: (recover as bool?) ?? false,
                    errorListener: errorListener)),
        _domainHook = domainHook;

  /// The logger to use.
  final Logger log;

  /// The naming strategy to use.
  final NamingStrategy naming;

  /// Whether to enforce strict event naming (no interpolation).
  final bool strictEventNames;

  final ParameterParser _parameterParser;
  final SchemaValidator _validator;
  final LoadYamlNode _loadYamlNode;
  final void Function(String domainKey, YamlNode? valueNode)? _domainHook;

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
        parsedNode = _loadYamlNode(source.content);
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

        try {
          _validator.validateRootMap(parsedNode, source.filePath);
        } on AnalyticsParseException catch (e) {
          if (onError != null) {
            onError(e);
          } else {
            rethrow;
          }
          continue;
        }
      }

      final parsedMap = parsedNode as YamlMap;
      final sortedDomainKeys = parsedMap.nodes.keys.toList()
        ..sort((a, b) => a.toString().compareTo(b.toString()));

      for (final keyNode in sortedDomainKeys) {
        final domainKey = keyNode.toString();
        final valueNode = parsedMap.nodes[keyNode];

        if (valueNode == null) {
          continue;
        }

        try {
          // Test seam: allow tests to inject behavior that runs within the
          // domain-level try-block. This enables creating scenarios that
          // result in non-Analytics exceptions and ensure they are wrapped
          // appropriately.
          if (_domainHook != null) {
            _domainHook!(domainKey, valueNode);
          }
          // Enforce snake_case, filesystem-safe domain names
          _validator.validateDomainName(domainKey, source.filePath);

          if (merged.containsKey(domainKey)) {
            throw AnalyticsParseException(
              'Duplicate domain "$domainKey" found in multiple files. '
              'Each domain must be defined in only one file.',
              filePath: source.filePath,
              span: (keyNode is YamlNode) ? keyNode.span : null,
            );
          }

          _validator.validateDomainMap(valueNode, domainKey, source.filePath);

          merged[domainKey] = _DomainSource(
            filePath: source.filePath,
            yaml: valueNode as YamlMap,
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
        strictEventNames: strictEventNames,
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
        _validator.validateEventName(eventName, filePath, span: keyNode.span);

        _validator.validateEventMap(valueNode, domainName, eventName, filePath);

        final eventData = valueNode as YamlMap;

        final description =
            eventData['description'] as String? ?? 'No description provided';
        final customEventName = eventData['event_name'] as String?;

        if (customEventName != null) {
          final customEventNameNode = eventData.nodes['event_name'];
          _validator.validateEventName(
            customEventName,
            filePath,
            span: customEventNameNode?.span,
          );
        }
        final identifier = eventData['identifier'] as String?;
        final deprecated = eventData['deprecated'] as bool? ?? false;
        final replacement = eventData['replacement'] as String?;

        final metaNode = eventData.nodes['meta'];
        final meta = _parseMeta(metaNode, filePath);

        final rawParameters = eventData.nodes['parameters'];
        if (rawParameters != null) {
          _validator.validateParametersMap(
            rawParameters,
            domainName,
            eventName,
            filePath,
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
            sourcePath: filePath,
            lineNumber: keyNode.span.start.line + 1,
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
    _validator.validateMetaMap(metaNode, filePath);
    // Convert YamlMap to Map<String, Object?>
    return (metaNode as YamlMap)
        .map((key, value) => MapEntry(key.toString(), value));
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
        parsedNode = _loadYamlNode(source.content);
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

      _validator.validateContextRoot(parsedNode, source.filePath);

      final yaml = parsedNode;

      final contextNameNode = yaml.nodes.keys.first as YamlNode;
      final contextName = contextNameNode.toString();
      final propertiesNode = yaml.nodes[contextNameNode];

      // If the YAML key is present but the value is effectively missing / null
      // (for example, `context_name:` with no mapping), treat it as missing.
      if (propertiesNode == null ||
          (propertiesNode is YamlScalar && propertiesNode.value == null)) {
        throw AnalyticsParseException(
          'The "$contextName" key must be a map of properties.',
          filePath: source.filePath,
          span: contextNameNode.span,
        );
      }

      _validator.validateContextProperties(
        propertiesNode,
        contextName,
        source.filePath,
      );

      final parameters = _parameterParser.parseParameters(
        propertiesNode as YamlMap,
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
  _DomainSource({
    required this.filePath,
    required this.yaml,
  });
  final String filePath;
  final YamlMap yaml;
}
