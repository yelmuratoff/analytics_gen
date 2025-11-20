import 'naming_strategy.dart';

/// Configuration for analytics code generation
final class AnalyticsConfig {
  /// Path to directory containing YAML event files (relative to project root)
  final String eventsPath;

  /// Path where generated Dart code will be written (relative to lib/)
  final String outputPath;

  /// Path where documentation will be generated (optional)
  final String? docsPath;

  /// Path where database exports will be generated (optional)
  final String? exportsPath;

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

  /// Naming controls applied across parsing and generation.
  final NamingStrategy naming;

  /// List of paths to context definition files (relative to project root).
  /// These files define stateful properties (e.g. user properties, session context).
  final List<String> contexts;

  const AnalyticsConfig({
    this.eventsPath = 'events',
    this.outputPath = 'src/analytics/generated',
    this.docsPath,
    this.exportsPath,
    this.generateCsv = false,
    this.generateJson = false,
    this.generateSql = false,
    this.generateDocs = false,
    this.generatePlan = true,
    this.includeEventDescription = false,
    this.strictEventNames = true,
    this.naming = const NamingStrategy(),
    this.contexts = const [],
  });

  /// Creates config from YAML map
  factory AnalyticsConfig.fromYaml(Map<dynamic, dynamic> yaml) {
    final config = yaml['analytics_gen'] as Map<dynamic, dynamic>? ?? {};

    return AnalyticsConfig(
      eventsPath: config['events_path'] as String? ?? 'events',
      outputPath: config['output_path'] as String? ?? 'src/analytics/generated',
      docsPath: config['docs_path'] as String?,
      exportsPath: config['exports_path'] as String?,
      generateCsv: config['generate_csv'] as bool? ?? false,
      generateJson: config['generate_json'] as bool? ?? false,
      generateSql: config['generate_sql'] as bool? ?? false,
      generateDocs: config['generate_docs'] as bool? ?? false,
      generatePlan: config['generate_plan'] as bool? ?? true,
      includeEventDescription:
          config['include_event_description'] as bool? ?? false,
      strictEventNames: config['strict_event_names'] as bool? ?? true,
      naming: NamingStrategy.fromYaml(config['naming'] as Map?),
      contexts: (config['contexts'] as List?)?.cast<String>() ?? const [],
    );
  }

  /// Default configuration
  static const AnalyticsConfig defaultConfig = AnalyticsConfig();
}
