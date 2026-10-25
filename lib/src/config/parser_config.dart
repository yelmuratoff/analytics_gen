import '../models/analytics_parameter.dart';
import 'naming_strategy.dart';

/// Configuration options for the YAML parser.
class ParserConfig {
  /// Creates a new parser configuration.
  const ParserConfig({
    this.naming = const NamingStrategy(),
    this.strictEventNames = true,
    this.enforceCentrallyDefinedParameters = false,
    this.preventEventParameterDuplicates = false,
    this.sharedParameters = const {},
  });

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
}
