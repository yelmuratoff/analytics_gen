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
    final config = yaml['analytics_gen'] as Map<dynamic, dynamic>? ?? {};
    final inputs = config['inputs'] as Map<dynamic, dynamic>? ?? {};
    final outputs = config['outputs'] as Map<dynamic, dynamic>? ?? {};
    final targets = config['targets'] as Map<dynamic, dynamic>? ?? {};
    final rules = config['rules'] as Map<dynamic, dynamic>? ?? {};

    return AnalyticsConfig(
      eventsPath:
          (inputs['events'] ?? config['events_path']) as String? ?? 'events',
      outputPath: (outputs['dart'] ?? config['output_path']) as String? ??
          'src/analytics/generated',
      docsPath: (outputs['docs'] ?? config['docs_path']) as String?,
      exportsPath: (outputs['exports'] ?? config['exports_path']) as String?,
      sharedParameters:
          (inputs['shared_parameters'] ?? config['shared_parameters'] as List?)
                  ?.cast<String>() ??
              const [],
      generateCsv: (targets['csv'] ?? config['generate_csv']) as bool? ?? false,
      generateJson:
          (targets['json'] ?? config['generate_json']) as bool? ?? false,
      generateSql: (targets['sql'] ?? config['generate_sql']) as bool? ?? false,
      generateDocs:
          (targets['docs'] ?? config['generate_docs']) as bool? ?? false,
      generatePlan:
          (targets['plan'] ?? config['generate_plan']) as bool? ?? true,
      includeEventDescription: (rules['include_event_description'] ??
              config['include_event_description']) as bool? ??
          false,
      strictEventNames: (rules['strict_event_names'] ??
              config['strict_event_names']) as bool? ??
          true,
      enforceCentrallyDefinedParameters:
          (rules['enforce_centrally_defined_parameters'] ??
                  config['enforce_centrally_defined_parameters']) as bool? ??
              false,
      preventEventParameterDuplicates:
          (rules['prevent_event_parameter_duplicates'] ??
                  config['prevent_event_parameter_duplicates']) as bool? ??
              false,
      naming: NamingStrategy.fromYaml(config['naming'] as Map?),
      contexts:
          (inputs['contexts'] ?? config['contexts'] as List?)?.cast<String>() ??
              const [],
      imports:
          (inputs['imports'] ?? config['imports'] as List?)?.cast<String>() ??
              const [],
      generateTestMatchers: (targets['test_matchers'] ??
              config['generate_test_matchers']) as bool? ??
          false,
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
