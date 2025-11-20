import '../../config/analytics_config.dart';
import '../../models/analytics_event.dart';
import '../../util/string_utils.dart';
import 'base_renderer.dart';

class AnalyticsClassRenderer extends BaseRenderer {
  final AnalyticsConfig config;

  const AnalyticsClassRenderer(this.config);

  String renderAnalyticsClass(
    Map<String, AnalyticsDomain> domains, {
    Map<String, List<AnalyticsParameter>> contexts = const {},
    String? planFingerprint,
  }) {
    final buffer = StringBuffer();

    // File header
    buffer.write(renderFileHeader());
    buffer.writeln("import 'package:analytics_gen/analytics_gen.dart';");
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
      buffer.write(_generateAnalyticsPlanField(domains));
      buffer.writeln();
    }

    if (planFingerprint != null) {
      buffer.writeln('  /// The fingerprint of the plan used to generate this code.');
      buffer.writeln("  static const String planFingerprint = '$planFingerprint';");
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
        "      throw StateError('Analytics.initialize() must be called before accessing Analytics.instance');");
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

  String _generateAnalyticsPlanField(Map<String, AnalyticsDomain> domains) {
    final buffer = StringBuffer();
    buffer.writeln('  /// Runtime view of the generated tracking plan.');
    buffer.writeln(
      '  static const List<AnalyticsDomain> plan = <AnalyticsDomain>[',
    );

    final sortedDomains = domains.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in sortedDomains) {
      buffer.write(_analyticsDomainPlanEntry(entry.value));
    }

    buffer.writeln('  ];');
    return buffer.toString();
  }

  String _analyticsDomainPlanEntry(AnalyticsDomain domain) {
    final buffer = StringBuffer();
    buffer.writeln('    AnalyticsDomain(');
    buffer.writeln(
        "      name: '${StringUtils.escapeSingleQuoted(domain.name)}',");
    buffer.writeln('      events: <AnalyticsEvent>[');

    for (final event in domain.events) {
      buffer.write(_analyticsEventPlanEntry(event));
    }

    buffer.writeln('      ],');
    buffer.writeln('    ),');
    return buffer.toString();
  }

  String _analyticsEventPlanEntry(AnalyticsEvent event) {
    final buffer = StringBuffer();
    buffer.writeln('        AnalyticsEvent(');
    buffer.writeln(
        "          name: '${StringUtils.escapeSingleQuoted(event.name)}',");
    buffer.writeln(
      "          description: '${StringUtils.escapeSingleQuoted(event.description)}',",
    );
    if (event.identifier != null) {
      buffer.writeln(
        "          identifier: '${StringUtils.escapeSingleQuoted(event.identifier!)}',",
      );
    }
    if (event.customEventName != null) {
      buffer.writeln(
        "          customEventName: '${StringUtils.escapeSingleQuoted(event.customEventName!)}',",
      );
    }
    buffer.writeln('          deprecated: ${event.deprecated},');
    if (event.replacement != null) {
      buffer.writeln(
        "          replacement: '${StringUtils.escapeSingleQuoted(event.replacement!)}',",
      );
    }
    if (event.meta.isNotEmpty) {
      buffer.writeln('          meta: <String, Object?>{');
      for (final entry in event.meta.entries) {
        buffer.writeln(
          "            '${StringUtils.escapeSingleQuoted(entry.key)}': '${StringUtils.escapeSingleQuoted(entry.value.toString())}',",
        );
      }
      buffer.writeln('          },');
    }
    buffer.writeln('          parameters: <AnalyticsParameter>[');

    for (final param in event.parameters) {
      buffer.write(_analyticsParameterPlanEntry(param));
    }

    buffer.writeln('          ],');
    buffer.writeln('        ),');
    return buffer.toString();
  }

  String _analyticsParameterPlanEntry(AnalyticsParameter param) {
    final buffer = StringBuffer();
    buffer.writeln('            AnalyticsParameter(');
    buffer.writeln(
        "              name: '${StringUtils.escapeSingleQuoted(param.name)}',");
    if (param.codeName != param.name) {
      buffer.writeln(
        "              codeName: '${StringUtils.escapeSingleQuoted(param.codeName)}',",
      );
    }
    buffer.writeln(
        "              type: '${StringUtils.escapeSingleQuoted(param.type)}',");
    buffer.writeln('              isNullable: ${param.isNullable},');
    if (param.description != null) {
      buffer.writeln(
        "              description: '${StringUtils.escapeSingleQuoted(param.description!)}',",
      );
    }
    if (param.allowedValues != null && param.allowedValues!.isNotEmpty) {
      buffer.writeln('              allowedValues: <String>[');
      for (final value in param.allowedValues!) {
        buffer.writeln(
          "                '${StringUtils.escapeSingleQuoted(value)}',",
        );
      }
      buffer.writeln('              ],');
    }
    if (param.meta.isNotEmpty) {
      buffer.writeln('              meta: <String, Object?>{');
      for (final entry in param.meta.entries) {
        buffer.writeln(
          "                '${StringUtils.escapeSingleQuoted(entry.key)}': '${StringUtils.escapeSingleQuoted(entry.value.toString())}',",
        );
      }
      buffer.writeln('              },');
    }
    buffer.writeln('            ),');
    return buffer.toString();
  }
}
