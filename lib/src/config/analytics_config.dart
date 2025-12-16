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

  /// Default configuration
  static const AnalyticsConfig defaultConfig = AnalyticsConfig();

  /// The main package import uri.
  static const String kPackageImport =
      'package:analytics_gen/analytics_gen.dart';

  /// Path to directory containing YAML event files (relative to project root).
  ///
  /// Defaults to `events`.
  final String eventsPath;

  /// Path where generated Dart code will be written (relative to lib/).
  ///
  /// Defaults to `src/analytics/generated`.
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
