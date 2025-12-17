import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';
import 'package:yaml/yaml.dart';

import '../config/parser_config.dart';
import '../util/logger.dart';
import 'context_parser.dart';
import 'domain_parser.dart';
import 'event_loader.dart';
import 'parameter_parser.dart';
import 'schema_validator.dart';
import 'shared_parameter_parser.dart';

/// Parses YAML files containing analytics event definitions.
typedef LoadYamlNode = YamlNode Function(String,
    {dynamic sourceUrl, dynamic recover, dynamic errorListener});

/// YAML parser for analytics event definitions.
final class YamlParser {
  /// Creates a new YAML parser.
  YamlParser({
    this.log = const NoOpLogger(),
    this.config = const ParserConfig(),
    SchemaValidator? validator,
    LoadYamlNode? loadYaml,
    DomainParser? domainParser,
    ContextParser? contextParser,
    SharedParameterParser? sharedParameterParser,
    void Function(String domainKey, YamlNode? valueNode)? domainHook,
  }) : _loadYamlNode = loadYaml ??
            ((String content,
                    {dynamic sourceUrl,
                    dynamic recover,
                    dynamic errorListener}) =>
                loadYamlNode(content,
                    sourceUrl: sourceUrl as Uri?,
                    recover: (recover as bool?) ?? false,
                    errorListener: errorListener)) {
    _validator = validator ??
        SchemaValidator(
          config.naming,
          strictEventNames: config.strictEventNames,
        );

    _domainParser = domainParser ??
        DomainParser(
          validator: _validator,
          loadYamlNode: _loadYamlNode,
          naming: config.naming,
          log: log,
          strictEventNames: config.strictEventNames,
          enforceCentrallyDefinedParameters:
              config.enforceCentrallyDefinedParameters,
          preventEventParameterDuplicates:
              config.preventEventParameterDuplicates,
          sharedParameters: config.sharedParameters,
          domainHook: domainHook,
        );
    _contextParser = contextParser ??
        ContextParser(
          validator: _validator,
          loadYamlNode: _loadYamlNode,
          naming: config.naming,
        );
    _sharedParameterParser = sharedParameterParser ??
        SharedParameterParser(
          validator: _validator,
          loadYamlNode: _loadYamlNode,
          naming: config.naming,
        );
  }

  /// The logger to use.
  final Logger log;

  /// The parser configuration.
  final ParserConfig config;

  late final SchemaValidator _validator;
  late final DomainParser _domainParser;
  late final ContextParser _contextParser;
  late final SharedParameterParser _sharedParameterParser;
  final LoadYamlNode _loadYamlNode;

  /// Parses the provided analytics sources and returns a map of domains.
  Future<Map<String, AnalyticsDomain>> parseEvents(
    List<AnalyticsSource> sources,
  ) {
    return _domainParser.parseEvents(sources);
  }

  /// Parses shared parameters from a YAML source.
  Map<String, AnalyticsParameter> parseSharedParameters(
    AnalyticsSource source,
  ) {
    return _sharedParameterParser.parse(source);
  }

  /// Public helper used by tests to exercise parameter parsing logic
  /// without traversing the full YAML loader pipeline.
  List<AnalyticsParameter> parseParameters(
    YamlMap parametersYaml, {
    required String domainName,
    required String eventName,
    required String filePath,
  }) {
    return ParameterParser.parseParameters(
      parametersYaml,
      domainName: domainName,
      eventName: eventName,
      filePath: filePath,
      naming: config.naming,
      sharedParameters: config.sharedParameters,
      enforceCentrallyDefinedParameters:
          config.enforceCentrallyDefinedParameters,
      preventEventParameterDuplicates: config.preventEventParameterDuplicates,
    );
  }

  /// Parses all configured context files.
  /// Returns a map where the key is the context name (from the YAML root key)
  /// and the value is the list of parameters.
  Future<Map<String, List<AnalyticsParameter>>> parseContexts(
    List<AnalyticsSource> sources,
  ) {
    return _contextParser.parseContexts(sources);
  }
}
