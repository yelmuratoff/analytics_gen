import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';
import 'package:yaml/yaml.dart';

import '../config/naming_strategy.dart';
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
    NamingStrategy? naming,
    this.strictEventNames = true,
    this.enforceCentrallyDefinedParameters = false,
    this.preventEventParameterDuplicates = false,
    this.sharedParameters = const {},
    SchemaValidator? validator,
    LoadYamlNode? loadYaml,
    void Function(String domainKey, YamlNode? valueNode)? domainHook,
  })  : naming = naming ?? const NamingStrategy(),
        _loadYamlNode = loadYaml ??
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
          this.naming,
          strictEventNames: strictEventNames,
        );
    _parameterParser = ParameterParser(this.naming);
    _domainParser = DomainParser(
      parameterParser: _parameterParser,
      validator: _validator,
      loadYamlNode: _loadYamlNode,
      naming: this.naming,
      log: log,
      strictEventNames: strictEventNames,
      enforceCentrallyDefinedParameters: enforceCentrallyDefinedParameters,
      preventEventParameterDuplicates: preventEventParameterDuplicates,
      sharedParameters: sharedParameters,
      domainHook: domainHook,
    );
    _contextParser = ContextParser(
      parameterParser: _parameterParser,
      validator: _validator,
      loadYamlNode: _loadYamlNode,
    );
    _sharedParameterParser = SharedParameterParser(
      parameterParser: _parameterParser,
      validator: _validator,
      loadYamlNode: _loadYamlNode,
    );
  }

  /// The logger to use.
  final Logger log;

  /// The naming strategy to use.
  final NamingStrategy naming;

  /// Whether to enforce strict event naming (no interpolation).
  final bool strictEventNames;

  /// Whether to enforce that all parameters must be defined in the shared
  /// parameters file.
  final bool enforceCentrallyDefinedParameters;

  /// Whether to prevent defining parameters in events that are already defined
  /// in the shared parameters file.
  final bool preventEventParameterDuplicates;

  /// Shared parameters available to all events.
  final Map<String, AnalyticsParameter> sharedParameters;

  late final ParameterParser _parameterParser;
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
  ) {
    return _contextParser.parseContexts(sources);
  }
}
