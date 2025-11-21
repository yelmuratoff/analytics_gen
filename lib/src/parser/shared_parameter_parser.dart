import 'package:yaml/yaml.dart';

import '../core/exceptions.dart';
import '../models/analytics_event.dart';
import 'event_loader.dart';
import 'parameter_parser.dart';
import 'schema_validator.dart';
import 'yaml_parser.dart';

/// Parses shared parameters from YAML sources.
class SharedParameterParser {
  /// Creates a new shared parameter parser.
  const SharedParameterParser({
    required this.parameterParser,
    required this.validator,
    required this.loadYamlNode,
  });

  final ParameterParser parameterParser;
  final SchemaValidator validator;
  final LoadYamlNode loadYamlNode;

  /// Parses shared parameters from a YAML source.
  Map<String, AnalyticsParameter> parse(AnalyticsSource source) {
    final YamlNode parsedNode;
    try {
      parsedNode = loadYamlNode(source.content);
    } catch (e) {
      throw AnalyticsParseException(
        'Failed to parse shared parameters YAML: $e',
        filePath: source.filePath,
        innerError: e,
      );
    }

    if (parsedNode is! YamlMap) {
      // If empty or just comments
      if (parsedNode is YamlScalar && parsedNode.value == null) {
        return {};
      }
      throw AnalyticsParseException(
        'Shared parameters file must be a map.',
        filePath: source.filePath,
        span: parsedNode.span,
      );
    }

    final parsedMap = parsedNode;
    final parametersNode = parsedMap.nodes['parameters'];

    if (parametersNode == null) {
      return {};
    }

    if (parametersNode is! YamlMap) {
      throw AnalyticsParseException(
        'The "parameters" key must be a map.',
        filePath: source.filePath,
        span: parametersNode.span,
      );
    }

    validator.validateParametersMap(
      parametersNode,
      'shared',
      'shared',
      source.filePath,
    );

    final parametersList = parameterParser.parseParameters(
      parametersNode,
      domainName: 'shared',
      eventName: 'shared',
      filePath: source.filePath,
    );

    return {for (final p in parametersList) p.name: p};
  }
}
