import '../util/yaml_keys.dart';
import 'naming_strategy.dart';

/// Configuration for analytics code generation
final class AnalyticsConfig {
  /// Creates a new analytics configuration.
  const AnalyticsConfig({
    this.eventsPath = 'events',
    this.outputPath = 'src/analytics/generated',
    this.docsPath,
    this.exportsPath,
    this.sharedParameters = const [],
    this.generateCsv = false,
    this.generateJson = false,
    this.generateSql = false,
    this.generateDocs = false,
    this.generatePlan = true,
    this.includeEventDescription = false,
    this.strictEventNames = true,
    this.enforceCentrallyDefinedParameters = false,
    this.preventEventParameterDuplicates = false,
    this.naming = const NamingStrategy(),
    this.contexts = const [],
    this.imports = const [],
    this.generateTestMatchers = false,
  });

  /// Creates config from YAML map
  factory AnalyticsConfig.fromYaml(Map<dynamic, dynamic> yaml) {
    if (yaml.isEmpty) return const AnalyticsConfig();

    T cast<T>(dynamic value, String context) {
      if (value == null) return null as T;
      if (value is T) return value;
      throw FormatException(
          'Invalid configuration for "$context": Expected $T but got ${value.runtimeType}');
    }

    Map<dynamic, dynamic> safeMap(dynamic map, String context) {
      if (map == null) return {};
      if (map is Map) return map;
      throw FormatException(
          'Invalid configuration for "$context": Expected Map but got ${map.runtimeType}');
    }

    final config = safeMap(yaml[YamlKeys.analyticsGen], YamlKeys.analyticsGen);
    final inputs = safeMap(config[YamlKeys.inputs], YamlKeys.inputs);
    final outputs = safeMap(config[YamlKeys.outputs], YamlKeys.outputs);
    final targets = safeMap(config[YamlKeys.targets], YamlKeys.targets);
    final rules = safeMap(config[YamlKeys.rules], YamlKeys.rules);

    T val<T>(Map map, String key, T defaultVal) {
      final v = map[key];
      if (v == null) return defaultVal;
      return cast<T>(v, key);
    }

    List<String> list(Map map, String key, List<String> defaultVal) {
      final v = map[key];
      if (v == null) return defaultVal;
      if (v is! List) {
        throw FormatException(
            'Invalid configuration for "$key": Expected List but got ${v.runtimeType}');
      }
      return v.map((e) => e.toString()).toList();
    }

    return AnalyticsConfig(
      eventsPath: val(
          inputs, YamlKeys.events, val(config, YamlKeys.eventsPath, 'events')),
      outputPath: val(outputs, YamlKeys.dart,
          val(config, YamlKeys.outputPath, 'src/analytics/generated')),
      docsPath:
          val(outputs, YamlKeys.docs, val(config, YamlKeys.docsPath, null)),
      exportsPath: val(
          outputs, YamlKeys.exports, val(config, YamlKeys.exportsPath, null)),
      sharedParameters: list(inputs, YamlKeys.sharedParameters,
          list(config, YamlKeys.sharedParameters, [])),
      generateCsv:
          val(targets, YamlKeys.csv, val(config, YamlKeys.generateCsv, false)),
      generateJson: val(
          targets, YamlKeys.json, val(config, YamlKeys.generateJson, false)),
      generateSql:
          val(targets, YamlKeys.sql, val(config, YamlKeys.generateSql, false)),
      generateDocs: val(
          targets, YamlKeys.docs, val(config, YamlKeys.generateDocs, false)),
      generatePlan:
          val(targets, YamlKeys.plan, val(config, YamlKeys.generatePlan, true)),
      includeEventDescription: val(rules, YamlKeys.includeEventDescription,
          val(config, YamlKeys.includeEventDescription, false)),
      strictEventNames: val(rules, YamlKeys.strictEventNames,
          val(config, YamlKeys.strictEventNames, true)),
      enforceCentrallyDefinedParameters: val(
          rules,
          YamlKeys.enforceCentrallyDefinedParameters,
          val(config, YamlKeys.enforceCentrallyDefinedParameters, false)),
      preventEventParameterDuplicates: val(
          rules,
          YamlKeys.preventEventParameterDuplicates,
          val(config, YamlKeys.preventEventParameterDuplicates, false)),
      naming: NamingStrategy.fromYaml(config[YamlKeys.naming] as Map?),
      contexts:
          list(inputs, YamlKeys.contexts, list(config, YamlKeys.contexts, [])),
      imports:
          list(inputs, YamlKeys.imports, list(config, YamlKeys.imports, [])),
      generateTestMatchers: val(targets, YamlKeys.testMatchers,
          val(config, YamlKeys.generateTestMatchers, false)),
    );
  }

  /// Default configuration
  static const AnalyticsConfig defaultConfig = AnalyticsConfig();

  /// The main package import uri.
  static const String kPackageImport =
      'package:analytics_gen/analytics_gen.dart';

  /// Path to directory containing YAML event files (relative to project root)
  final String eventsPath;

  /// Path where generated Dart code will be written (relative to lib/)
  final String outputPath;

  /// Path where documentation will be generated (optional)
  final String? docsPath;

  /// Path where database exports will be generated (optional)
  final String? exportsPath;

  /// List of paths to shared event parameter files (relative to project root).
  final List<String> sharedParameters;

  /// Whether to generate CSV export
  final bool generateCsv;

  /// Whether to generate JSON export
  final bool generateJson;

  /// Whether to generate SQL export
  final bool generateSql;

  /// Whether to generate documentation
  final bool generateDocs;

  /// Whether to include the runtime tracking plan in generated code.
  final bool generatePlan;

  /// Whether to include the event 'description' as a parameter when logging
  /// events.
  final bool includeEventDescription;

  /// Whether to treat string interpolation in event names as an error.
  ///
  /// When true, events with names like "Page View: ${page_name}" will cause
  /// generation to fail. This prevents high-cardinality events.
  final bool strictEventNames;

  /// Whether to enforce that all parameters must be defined in the shared
  /// parameters file.
  final bool enforceCentrallyDefinedParameters;

  /// Whether to prevent defining parameters in events that are already defined
  /// in the shared parameters file.
  final bool preventEventParameterDuplicates;

  /// Naming controls applied across parsing and generation.
  final NamingStrategy naming;

  /// List of paths to context definition files (relative to project root).
  /// These files define stateful properties (e.g. user properties, session context).
  final List<String> contexts;

  /// List of custom imports to include in generated files.
  /// This is useful for importing external types used in `dart_type`.
  final List<String> imports;

  /// Whether to generate test matchers for `package:test`.
  final bool generateTestMatchers;
}
