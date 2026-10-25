import 'package:analytics_gen/src/models/analytics_parameter.dart';
import 'package:yaml/yaml.dart';

import '../config/naming_strategy.dart';
import '../core/exceptions.dart';
import '../util/logger.dart';
import '../util/yaml_keys.dart';
import 'event_loader.dart';
import 'parameter_parser.dart';
import 'schema_validator.dart';
import 'yaml_fields.dart';
import 'yaml_parser.dart';

/// Parses shared parameters from YAML sources.
class SharedParameterParser {
  /// Creates a new shared parameter parser.
  const SharedParameterParser({
    required this.naming,
    required this.validator,
    required this.loadYamlNode,
    this.log = const NoOpLogger(),
  });

  /// The naming strategy to use.
  final NamingStrategy naming;

  /// The logger that receives warnings about ignored fields.
  final Logger log;

  /// The schema validator used to validate the structure and types
  /// of the shared parameters YAML before parsing.
  final SchemaValidator validator;

  /// A callback to load YAML into a `YamlNode` from a string. This is
  /// injected to facilitate testing and to avoid a direct dependency on
  /// `package:yaml` in places where different loading behavior is needed.
  final LoadYamlNode loadYamlNode;

  /// Parses shared parameters from a YAML source.
  Map<String, AnalyticsParameter> parse(AnalyticsSource source) {
    final parsedNode = loadSourceYaml(loadYamlNode, source);

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
    parsedMap.warnUnknownFields(
      YamlKeys.sharedParametersFileFields,
      owner: 'the shared parameters file',
      filePath: source.filePath,
      log: log,
    );
    final parametersNode = parsedMap.nodes[YamlKeys.parameters];

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

    final parametersList = ParameterParser.parseParameters(
      parametersNode,
      domainName: 'shared',
      eventName: 'shared',
      filePath: source.filePath,
      naming: naming,
      log: log,
    );

    return {for (final p in parametersList) p.name: p};
  }
}
