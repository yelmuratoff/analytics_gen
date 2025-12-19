import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';

import '../../config/analytics_config.dart';
import '../../util/string_utils.dart';
import 'base_renderer.dart';
import 'enum_renderer.dart';

/// Renders Matchers for package:test.
class MatchersRenderer extends BaseRenderer {
  /// Creates a new matchers renderer.
  const MatchersRenderer(this.config);

  /// The analytics configuration.
  final AnalyticsConfig config;

  /// Renders the matchers file content.
  String render(Map<String, AnalyticsDomain> domains) {
    final buffer = StringBuffer();

    buffer.write(renderFileHeader());

    final imports = <String>[
      'package:test/test.dart',
      // We need to import the generated events to access Enums if needed
      '../${config.outputs.dartPath}/generated_events.dart',
    ];

    buffer.write(renderImports(imports));

    // Add type definition for convenience
    buffer.writeln('/// Key-value pair for event parameters');
    buffer.writeln('typedef EventParams = Map<String, Object?>;');
    buffer.writeln();

    for (final domain in domains.values) {
      buffer.writeln('// Domain: ${domain.name}');
      for (final event in domain.events) {
        buffer.write(_renderEventMatcher(domain.name, event));
      }
    }

    return buffer.toString();
  }

  String _renderEventMatcher(String domainName, AnalyticsEvent event) {
    final buffer = StringBuffer();
    // e.g. strictlyLogAuthLogin
    // final matcherName = ... (unused)

    final eventNamePascal = StringUtils.capitalizePascal(domainName) +
        StringUtils.capitalizePascal(event.name);
    final finalMatcherName = 'is$eventNamePascal';

    buffer.writeln('/// Matcher for $domainName.${event.name}');
    if (event.parameters.isEmpty) {
      buffer.writeln('Matcher $finalMatcherName() {');
    } else {
      buffer.writeln('Matcher $finalMatcherName({');
      for (final param in event.parameters) {
        final camelParam = StringUtils.toCamelCase(param.codeName);
        buffer.writeln('  Object? $camelParam,');
      }
      buffer.writeln('}) {');
    }
    buffer.writeln('  return predicate((item) {');
    buffer.writeln('    if (item is! Map) return false;');
    if (event.parameters.isNotEmpty) {
      buffer.writeln('    final Map<String, dynamic> params = Map.from(item);');
    }
    buffer.writeln();

    // We expect the logEvent call to have 'name' and 'parameters'.
    // Wait, the item being matched is usually the map passed to `logEvent`.
    // If we mock `logEvent({required String name, required Map parameters})`,
    // we captured the named arguments.
    // Usually mocks capture named args as a Map<Symbol, dynamic>? Or if using verify:
    // verify(() => analytics.logEvent(name: '...', parameters: captureAnyNamed('parameters')));

    // Let's assume the user wants to match the `parameters` Map specifically,
    // OR the whole call?
    // The requirement is "Generate typed Matchers for package:test".
    // Usually used like:
    // verify(() => analytics.logEvent(name: 'foo', parameters: expectedParams)).called(1);
    // where expectedParams is what this matcher returns.
    // So this matcher matches [Map<String, Object?>].

    for (final param in event.parameters) {
      final camelParam = StringUtils.toCamelCase(param.codeName);
      // If the user didn't pass a matcher/value for this param, effectively "any" (ignore),
      // UNLESS we want strict matching.
      // Usually typed matchers imply "if you pass argument, check it".

      buffer.writeln('    if ($camelParam != null) {');
      buffer.writeln(
          '      if (!params.containsKey("${param.name}")) return false;');
      buffer.writeln('      final actual = params["${param.name}"];');

      // Check if $camelParam is a Matcher or a Value
      buffer.writeln('      if ($camelParam is Matcher) {');
      buffer.writeln(
          '        if (!$camelParam.matches(actual, {})) return false;');
      buffer.writeln('      } else {');
      // Handle Enum vs String comparison if needed.
      // The 'actual' is likely a String (if enum serialized) or the Enum itself depending on how logEvent works.
      // In `EventRenderer`, enums are serialized to .value (String) or .name before putting into map.
      // So actual is String.
      // But the user passed `AuthLoginMethod.email` into the matcher.

      final isEnum =
          param.type == 'string' && (param.allowedValues?.isNotEmpty ?? false);

      if (isEnum && param.dartType == null) {
        // params[key] will be String (serialized value).
        // $camelParam is Enum.
        final enumName =
            const EnumRenderer().buildEnumName(domainName, event, param);
        buffer.writeln('        if ($camelParam is $enumName) {');
        buffer.writeln(
            '          if (actual != $camelParam.value) return false;');
        buffer.writeln('        } else {');
        buffer.writeln('          if (actual != $camelParam) return false;');
        buffer.writeln('        }');
      } else if (param.dartType != null) {
        // External types (e.g. Enums) serialized as .name
        // `EventRenderer` uses `.name` for external types if nullable/not-nullable.
        // Assumption: External types in `dart_type` are usually Enums if they are simple.
        // But they could be anything.
        // If `logEvent` serialization used `.name`, actual is String.
        // If the user passed the object, we need to compare `actual` (String) with `expected.name`.
        // This is tricky without knowing if it is an enum.
        buffer.writeln('        // External type serialized as .name');
        buffer.writeln('        try {');
        buffer.writeln('           final dynamic dyn = $camelParam;');
        buffer.writeln('           if (actual != dyn.name) return false;');
        buffer.writeln('        } catch (_) {');
        buffer
            .writeln('           // Fallback if .name doesn\'t exist or match');
        buffer.writeln('           if (actual != $camelParam) return false;');
        buffer.writeln('        }');
      } else {
        buffer.writeln('        if (actual != $camelParam) return false;');
      }

      buffer.writeln('      }');
      buffer.writeln('    }');
    }

    buffer.writeln('    return true;');
    buffer.writeln('  });');
    buffer.writeln('}');
    buffer.writeln();

    return buffer.toString();
  }
}
