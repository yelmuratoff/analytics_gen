import '../../config/analytics_config.dart';
import '../../models/analytics_event.dart';
import '../../util/event_naming.dart';
import '../../util/string_utils.dart';
import 'base_renderer.dart';

/// Renders PII (Personally Identifiable Information) related code.
class PiiRenderer extends BaseRenderer {
  /// Creates a new PII renderer.
  const PiiRenderer(this.config);

  /// The analytics configuration.
  final AnalyticsConfig config;

  /// Renders the static _piiProperties field containing PII parameter keys.
  String renderPiiPropertiesField(Map<String, AnalyticsDomain> domains) {
    final buffer = StringBuffer();
    final piiMap = <String, Set<String>>{};

    for (final domain in domains.values) {
      for (final event in domain.events) {
        final piiParams = event.parameters
            .where((p) => p.meta['pii'] == true)
            .map((p) => p.name)
            .toSet();

        if (piiParams.isNotEmpty) {
          final eventName = EventNaming.resolveEventName(
            domain.name,
            event,
            config.naming,
          );
          piiMap[eventName] = piiParams;
        }
      }
    }

    if (piiMap.isEmpty) {
      buffer.writeln(
          '  static const Map<String, Set<String>> _piiProperties = {};');
      return buffer.toString();
    }

    buffer.writeln('  static const Map<String, Set<String>> _piiProperties = {');
    final sortedEvents = piiMap.keys.toList()..sort();
    for (final eventName in sortedEvents) {
      final params = piiMap[eventName]!.toList()..sort();
      final paramsString =
          params.map((p) => "'${StringUtils.escapeSingleQuoted(p)}'").join(', ');
      buffer.writeln(
        "    '${StringUtils.escapeSingleQuoted(eventName)}': {$paramsString},",
      );
    }
    buffer.writeln('  };');

    return buffer.toString();
  }

  /// Renders the static sanitizeParams method.
  String renderSanitizeParamsMethod() {
    final buffer = StringBuffer();
    buffer.writeln('  /// Returns a copy of [parameters] with PII values redacted.');
    buffer.writeln('  ///');
    buffer.writeln('  /// PII properties are defined in YAML with `meta: { pii: true }`.');
    buffer.writeln('  /// This method is useful for logging to console or non-secure backends.');
    buffer.writeln('  static Map<String, Object?> sanitizeParams(');
    buffer.writeln('    String eventName,');
    buffer.writeln('    Map<String, Object?>? parameters,');
    buffer.writeln('  ) {');
    buffer.writeln('    if (parameters == null || parameters.isEmpty) {');
    buffer.writeln('      return const {};');
    buffer.writeln('    }');
    buffer.writeln();
    buffer.writeln('    final piiKeys = _piiProperties[eventName];');
    buffer.writeln('    if (piiKeys == null) {');
    buffer.writeln('      return Map.of(parameters);');
    buffer.writeln('    }');
    buffer.writeln();
    buffer.writeln('    final sanitized = Map.of(parameters);');
    buffer.writeln('    for (final key in piiKeys) {');
    buffer.writeln('      if (sanitized.containsKey(key)) {');
    buffer.writeln("        sanitized[key] = '[REDACTED]';");
    buffer.writeln('      }');
    buffer.writeln('    }');
    buffer.writeln('    return sanitized;');
    buffer.writeln('  }');
    return buffer.toString();
  }
}
