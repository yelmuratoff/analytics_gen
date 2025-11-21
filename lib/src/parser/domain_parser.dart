import 'package:yaml/yaml.dart';

import '../config/naming_strategy.dart';
import '../core/exceptions.dart';
import '../models/analytics_event.dart';
import '../util/logger.dart';
import 'event_loader.dart';
import 'parameter_parser.dart';
import 'schema_validator.dart';
import 'yaml_parser.dart';

/// Parses analytics domains and events from YAML sources.
class DomainParser {
  /// Creates a new domain parser.
  const DomainParser({
    required this.parameterParser,
    required this.validator,
    required this.loadYamlNode,
    required this.naming,
    required this.log,
    this.strictEventNames = true,
    this.enforceCentrallyDefinedParameters = false,
    this.preventEventParameterDuplicates = false,
    this.sharedParameters = const {},
    this.domainHook,
  });

  final ParameterParser parameterParser;
  final SchemaValidator validator;
  final LoadYamlNode loadYamlNode;
  final NamingStrategy naming;
  final Logger log;
  final bool strictEventNames;
  final bool enforceCentrallyDefinedParameters;
  final bool preventEventParameterDuplicates;
  final Map<String, AnalyticsParameter> sharedParameters;
  final void Function(String domainKey, YamlNode? valueNode)? domainHook;

  /// Parses the provided analytics sources and returns a map of domains.
  Future<Map<String, AnalyticsDomain>> parseEvents(
    List<AnalyticsSource> sources,
  ) async {
    final domains = <String, AnalyticsDomain>{};
    final errors = <AnalyticsParseException>[];

    await for (final domain in _parseSources(
      sources,
      onError: errors.add,
    )) {
      domains[domain.name] = domain;
    }

    validator.validateUniqueEventNames(domains, onError: errors.add);

    if (errors.isNotEmpty) {
      throw AnalyticsAggregateException(errors);
    }

    return domains;
  }

  /// Internal helper to parse sources as a stream.
  Stream<AnalyticsDomain> _parseSources(
    List<AnalyticsSource> sources, {
    void Function(AnalyticsParseException)? onError,
  }) async* {
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

        try {
          validator.validateRootMap(parsedNode, source.filePath);
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
          // Test seam
          if (domainHook != null) {
            domainHook!(domainKey, valueNode);
          }
          // Enforce snake_case, filesystem-safe domain names
          validator.validateDomainName(domainKey, source.filePath);

          if (merged.containsKey(domainKey)) {
            throw AnalyticsParseException(
              'Duplicate domain "$domainKey" found in multiple files. '
              'Each domain must be defined in only one file.',
              filePath: source.filePath,
              span: (keyNode is YamlNode) ? keyNode.span : null,
            );
          }

          validator.validateDomainMap(valueNode, domainKey, source.filePath);

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

      try {
        final events = _parseEventsForDomain(
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
        validator.validateEventName(eventName, filePath, span: keyNode.span);

        validator.validateEventMap(valueNode, domainName, eventName, filePath);

        final eventData = valueNode as YamlMap;

        final description =
            eventData['description'] as String? ?? 'No description provided';
        final customEventName = eventData['event_name'] as String?;

        if (customEventName != null) {
          final customEventNameNode = eventData.nodes['event_name'];
          validator.validateEventName(
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
          validator.validateParametersMap(
            rawParameters,
            domainName,
            eventName,
            filePath,
          );
        }

        final parametersYaml = (rawParameters as YamlMap?) ?? YamlMap();
        final parameters = parameterParser.parseParameters(
          parametersYaml,
          domainName: domainName,
          eventName: eventName,
          filePath: filePath,
          sharedParameters: sharedParameters,
          enforceCentrallyDefinedParameters: enforceCentrallyDefinedParameters,
          preventEventParameterDuplicates: preventEventParameterDuplicates,
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
    validator.validateMetaMap(metaNode, filePath);
    // Convert YamlMap to Map<String, Object?>
    return (metaNode as YamlMap)
        .map((key, value) => MapEntry(key.toString(), value));
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
