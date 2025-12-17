import 'naming_strategy.dart';

/// Configuration for analytics code generation inputs.
class AnalyticsInputs {
  /// Creates a new inputs configuration.
  const AnalyticsInputs({
    this.eventsPath = 'events',
    this.contexts = const [],
    this.sharedParameters = const [],
    this.imports = const [],
  });

  /// Path to directory containing YAML event files (relative to project root).
  final String eventsPath;

  /// List of paths to context definition files.
  final List<String> contexts;

  /// List of paths to shared event parameter files.
  final List<String> sharedParameters;

  /// List of custom imports to include in generated files.
  final List<String> imports;
}

/// Configuration for analytics code generation outputs.
class AnalyticsOutputs {
  /// Creates a new outputs configuration.
  const AnalyticsOutputs({
    this.dartPath = 'src/analytics/generated',
    this.docsPath,
    this.exportsPath,
  });

  /// Path where generated Dart code will be written (relative to lib/).
  final String dartPath;

  /// Path where documentation will be generated (optional).
  final String? docsPath;

  /// Path where database exports will be generated (optional).
  final String? exportsPath;
}

/// Configuration for code generation targets.
class AnalyticsTargets {
  /// Creates a new targets configuration.
  const AnalyticsTargets({
    this.generateCsv = false,
    this.generateJson = false,
    this.generateSql = false,
    this.generateDocs = false,
    this.generatePlan = true,
    this.generateTestMatchers = false,
  });

  /// Whether to generate CSV export.
  final bool generateCsv;

  /// Whether to generate JSON export.
  final bool generateJson;

  /// Whether to generate SQL export.
  final bool generateSql;

  /// Whether to generate documentation.
  final bool generateDocs;

  /// Whether to include the runtime tracking plan in generated code.
  final bool generatePlan;

  /// Whether to generate test matchers for `package:test`.
  final bool generateTestMatchers;
}

/// Configuration for validation and generation rules.
class AnalyticsRules {
  /// Creates a new rules configuration.
  const AnalyticsRules({
    this.includeEventDescription = false,
    this.strictEventNames = true,
    this.enforceCentrallyDefinedParameters = false,
    this.preventEventParameterDuplicates = false,
  });

  /// Whether to include the event 'description' as a parameter.
  final bool includeEventDescription;

  /// Whether to treat string interpolation in event names as an error.
  final bool strictEventNames;

  /// Whether to enforce that all parameters must be defined in shared files.
  final bool enforceCentrallyDefinedParameters;

  /// Whether to prevent defining parameters in events that are duplicates.
  final bool preventEventParameterDuplicates;
}

/// Configuration for analytics code generation.
final class AnalyticsConfig {
  /// Creates a new analytics configuration.
  const AnalyticsConfig({
    this.inputs = const AnalyticsInputs(),
    this.outputs = const AnalyticsOutputs(),
    this.targets = const AnalyticsTargets(),
    this.rules = const AnalyticsRules(),
    this.naming = const NamingStrategy(),
  });

  /// Default configuration.
  static const AnalyticsConfig defaultConfig = AnalyticsConfig();

  /// The main package import uri.
  static const String kPackageImport =
      'package:analytics_gen/analytics_gen.dart';

  /// Input configuration.
  final AnalyticsInputs inputs;

  /// Output configuration.
  final AnalyticsOutputs outputs;

  /// Target configuration.
  final AnalyticsTargets targets;

  /// Rule configuration.
  final AnalyticsRules rules;

  /// Naming controls applied across parsing and generation.
  final NamingStrategy naming;
}
