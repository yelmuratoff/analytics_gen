import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';
import 'package:yaml/yaml.dart';

import '../config/naming_strategy.dart';
import '../core/exceptions.dart';
import '../util/logger.dart';
import 'domain_model_parser.dart';
import 'event_loader.dart';
import 'schema_validator.dart';
import 'yaml_parser.dart';

/// Parses analytics domains and events from YAML sources.
class DomainParser {
  /// Creates a new domain parser.
  const DomainParser({
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

  /// Validator used to assert the YAML structure and semantics of parsed
  /// domains and events conform to the schema.
  final SchemaValidator validator;

  /// Function that parses a YAML string into a `YamlNode` for downstream
  /// validation and parsing.
  final LoadYamlNode loadYamlNode;

  /// Naming convention and strategy used to map domain and parameter names to
  /// generated Dart identifiers (file names, class names, and parameter
  /// `codeName`s).
  final NamingStrategy naming;

  /// Logger used by the parser to emit warnings and debugging messages.
  final Logger log;

  /// Whether to enforce strict event names and disallow string interpolation
  /// inside event names to reduce cardinality.
  final bool strictEventNames;

  /// If enabled, parameters must be defined in shared configuration files and
  /// cannot be defined ad-hoc in events.
  final bool enforceCentrallyDefinedParameters;

  /// If enabled, prevents repeated parameter definitions in an event when the
  /// same parameter already exists in `sharedParameters`.
  final bool preventEventParameterDuplicates;

  /// Map of shared parameters (name -> definition) loaded from configured
  /// shared parameter files. These may be referenced by events across
  /// domains.
  final Map<String, AnalyticsParameter> sharedParameters;

  /// Optional test seam invoked for each domain key during parsing. Useful in
  /// tests to inspect intermediate YAML nodes or to inject behavior.
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
        final domain = DomainModelParser.parseDomain(
          domainName,
          eventsYaml,
          filePath: source.filePath,
          naming: naming,
          sharedParameters: sharedParameters,
          enforceCentrallyDefinedParameters: enforceCentrallyDefinedParameters,
          preventEventParameterDuplicates: preventEventParameterDuplicates,
          strictEventNames: strictEventNames,
          onError: onError,
        );
        yield domain;
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

final class _DomainSource {
  _DomainSource({
    required this.filePath,
    required this.yaml,
  });
  final String filePath;
  final YamlMap yaml;
}
