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

    final config = safeMap(yaml['analytics_gen'], 'analytics_gen');
    final inputs = safeMap(config['inputs'], 'inputs');
    final outputs = safeMap(config['outputs'], 'outputs');
    final targets = safeMap(config['targets'], 'targets');
    final rules = safeMap(config['rules'], 'rules');

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
      eventsPath: val(inputs, 'events', val(config, 'events_path', 'events')),
      outputPath: val(outputs, 'dart',
          val(config, 'output_path', 'src/analytics/generated')),
      docsPath: val(outputs, 'docs', val(config, 'docs_path', null)),
      exportsPath: val(outputs, 'exports', val(config, 'exports_path', null)),
      sharedParameters: list(
          inputs, 'shared_parameters', list(config, 'shared_parameters', [])),
      generateCsv: val(targets, 'csv', val(config, 'generate_csv', false)),
      generateJson: val(targets, 'json', val(config, 'generate_json', false)),
      generateSql: val(targets, 'sql', val(config, 'generate_sql', false)),
      generateDocs: val(targets, 'docs', val(config, 'generate_docs', false)),
      generatePlan: val(targets, 'plan', val(config, 'generate_plan', true)),
      includeEventDescription: val(rules, 'include_event_description',
          val(config, 'include_event_description', false)),
      strictEventNames: val(
          rules, 'strict_event_names', val(config, 'strict_event_names', true)),
      enforceCentrallyDefinedParameters: val(
          rules,
          'enforce_centrally_defined_parameters',
          val(config, 'enforce_centrally_defined_parameters', false)),
      preventEventParameterDuplicates: val(
          rules,
          'prevent_event_parameter_duplicates',
          val(config, 'prevent_event_parameter_duplicates', false)),
      naming: NamingStrategy.fromYaml(config['naming'] as Map?),
      contexts: list(inputs, 'contexts', list(config, 'contexts', [])),
      imports: list(inputs, 'imports', list(config, 'imports', [])),
      generateTestMatchers: val(targets, 'test_matchers',
          val(config, 'generate_test_matchers', false)),
    );
  }

  /// Default configuration
  static const AnalyticsConfig defaultConfig = AnalyticsConfig();

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
