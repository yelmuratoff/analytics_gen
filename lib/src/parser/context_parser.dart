import 'package:yaml/yaml.dart';

import '../core/exceptions.dart';
import '../models/analytics_event.dart';
import 'event_loader.dart';
import 'parameter_parser.dart';
import 'schema_validator.dart';
import 'yaml_parser.dart';

/// Parses context definitions from YAML sources.
class ContextParser {
  /// Creates a new context parser.
  const ContextParser({
    required this.parameterParser,
    required this.validator,
    required this.loadYamlNode,
  });

  /// Parser used to parse individual context parameters.
  final ParameterParser parameterParser;

  /// Validator used to assert that the YAML structure conforms to the
  /// expected context schema.
  final SchemaValidator validator;

  /// Function that parses a YAML string into a `YamlNode` instance.
  final LoadYamlNode loadYamlNode;

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

      validator.validateContextRoot(parsedNode, source.filePath);

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

      validator.validateContextProperties(
        propertiesNode,
        contextName,
        source.filePath,
      );

      final parameters = parameterParser.parseParameters(
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
