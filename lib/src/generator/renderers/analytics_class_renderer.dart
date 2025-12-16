import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';

import '../../config/analytics_config.dart';

import '../../util/string_utils.dart';
import '../serializers/plan_serializer.dart';
import 'base_renderer.dart';

/// Renders the main Analytics class with domain mixins and capabilities.
class AnalyticsClassRenderer extends BaseRenderer {
  /// Creates a new analytics class renderer.
  /// Creates a new analytics class renderer.
  AnalyticsClassRenderer(
    this.config, {
    this.planSerializer = const PlanSerializer(),
  });

  /// The analytics configuration.
  final AnalyticsConfig config;

  /// The plan serializer.
  final PlanSerializer planSerializer;

  /// Renders the Analytics class code.
  String renderAnalyticsClass(
    Map<String, AnalyticsDomain> domains, {
    Map<String, List<AnalyticsParameter>> contexts = const {},
    String? planFingerprint,
  }) {
    final buffer = StringBuffer();

    // File header
    buffer.write(renderFileHeader());
    buffer.writeln("import 'package:analytics_gen/analytics_gen.dart';");
    buffer.writeln("import 'package:meta/meta.dart';");
    buffer.writeln();
    buffer.writeln("import 'generated_events.dart';");

    for (final contextName in contexts.keys.toList()..sort()) {
      buffer.writeln("import 'contexts/${contextName}_context.dart';");
    }
    buffer.writeln();

    // Class documentation
    buffer.writeln('/// Main Analytics class.');
    buffer.writeln('///');
    buffer.writeln('/// Automatically generated with all domain mixins.');
    buffer
        .writeln('/// Supports both Dependency Injection and Singleton usage.');
    buffer.writeln('///');
    buffer.writeln('/// Usage (DI):');
    buffer.writeln('/// ```dart');
    buffer.writeln('/// final analytics = Analytics(YourAnalyticsService());');
    buffer.writeln('/// analytics.logAuthLogin(method: "email");');
    buffer.writeln('/// ```');
    buffer.writeln('///');
    buffer.writeln('/// Usage (Singleton):');
    buffer.writeln('/// ```dart');
    buffer.writeln('/// Analytics.initialize(YourAnalyticsService());');
    buffer.writeln('/// Analytics.instance.logAuthLogin(method: "email");');
    buffer.writeln('/// ```');

    // Add capabilities documentation if any contexts exist
    if (contexts.isNotEmpty) {
      buffer.writeln('///');
      buffer.writeln('/// ## Available Capabilities');
      buffer.writeln('///');
      buffer.writeln(
          '/// This class provides context property setters via capabilities:');
      buffer.writeln('///');

      for (final contextName in contexts.keys.toList()..sort()) {
        final pascalName = StringUtils.capitalizePascal(contextName);
        final camelName = StringUtils.toCamelCase(contextName);
        buffer.writeln('/// **$pascalName**');
        buffer.writeln('/// - Key: `${camelName}Key`');
        buffer.writeln('/// - Type: `${pascalName}Capability`');
        buffer.writeln('/// - Usage:');
        buffer.writeln('/// ```dart');
        buffer.writeln(
            '/// Analytics.instance.set${pascalName}PropertyName(value);');
        buffer.writeln('/// ```');
        buffer.writeln('///');
      }

      buffer.writeln(
          '/// Note: Capabilities are provider-specific. Ensure your analytics');
      buffer.writeln(
          '/// provider implements the required capability interfaces.');
    }

    // Generate mixin list
    final sortedDomains = domains.keys.toList()..sort();
    final mixins = sortedDomains
        .map((d) => 'Analytics${StringUtils.capitalizePascal(d)}')
        .toList();

    for (final contextName in contexts.keys.toList()..sort()) {
      mixins.add('Analytics${StringUtils.capitalizePascal(contextName)}');
    }

    // Class declaration
    buffer.write('final class Analytics extends AnalyticsBase');
    buffer.write(_buildAnalyticsMixinClause(mixins));

    buffer.writeln('{');

    // Fields
    buffer.writeln('  final IAnalytics _analytics;');
    buffer.writeln('  final AnalyticsCapabilityResolver _capabilities;');
    buffer.writeln();

    // Constructor
    buffer.writeln('  /// Constructor for Dependency Injection.');
    buffer.writeln('  const Analytics(');
    buffer.writeln('    this._analytics, [');
    buffer.writeln('    this._capabilities = const NullCapabilityResolver(),');
    buffer.writeln('  ]);');
    buffer.writeln();

    if (config.generatePlan) {
      buffer.write(planSerializer.generatePlanField(domains));
      buffer.writeln();
    }

    if (planFingerprint != null) {
      buffer.writeln(
          '  /// The fingerprint of the plan used to generate this code.');
      buffer.writeln(
          "  static const String planFingerprint = '$planFingerprint';");
      buffer.writeln();
    }

    // Singleton implementation
    buffer.writeln('  // --- Singleton Compatibility ---');
    buffer.writeln();
    buffer.writeln('  static Analytics? _instance;');
    buffer.writeln();
    buffer.writeln('  /// Access the singleton instance');
    buffer.writeln('  static Analytics get instance {');
    buffer.writeln('    if (_instance == null) {');
    buffer.writeln(
        "      throw StateError('Analytics.initialize() must be called before accessing Analytics.instance.\\nEnsure you call Analytics.initialize() in your main() function or before using any analytics features.');");
    buffer.writeln('    }');
    buffer.writeln('    return _instance!;');
    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  /// Whether analytics has been initialized');
    buffer.writeln('  static bool get isInitialized => _instance != null;');
    buffer.writeln();
    buffer.writeln('  /// Initialize analytics with your provider');
    buffer.writeln('  ///');
    buffer.writeln(
        '  /// Call this once at app startup before using any analytics methods.');
    buffer.writeln('  static void initialize(IAnalytics analytics) {');
    buffer.writeln('    if (_instance != null) {');
    buffer.writeln(
        "      throw StateError('Analytics is already initialized.');");
    buffer.writeln('    }');
    buffer.writeln(
        '    _instance = Analytics(analytics, analyticsCapabilitiesFor(analytics));');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Resets the singleton instance. Useful for testing.');
    buffer.writeln('  @visibleForTesting');
    buffer.writeln('  static void reset() {');
    buffer.writeln('    _instance = null;');
    buffer.writeln('  }');
    buffer.writeln();

    // Overrides
    buffer.writeln('  // --- Implementation ---');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  IAnalytics get logger => _analytics;');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln(
        '  AnalyticsCapabilityResolver get capabilities => _capabilities;');
    buffer.writeln('}');
    buffer.writeln();

    return buffer.toString();
  }

  String _buildAnalyticsMixinClause(List<String> mixins) {
    if (mixins.isEmpty) {
      return '\n';
    }

    if (mixins.length > 3) {
      final buffer = StringBuffer();
      buffer.writeln(' with');
      for (var i = 0; i < mixins.length; i++) {
        final comma = i < mixins.length - 1 ? ',' : '';
        buffer.writeln('    ${mixins[i]}$comma');
      }
      return buffer.toString();
    }

    return ' with ${mixins.join(', ')}\n';
  }
}
