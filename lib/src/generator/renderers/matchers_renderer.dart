import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';

import '../../config/analytics_config.dart';
import '../../util/model_codegen.dart';
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

    for (final param in event.parameters) {
      final camelParam = StringUtils.toCamelCase(param.codeName);
      final wireName = StringUtils.escapeDoubleQuoted(param.name);
      buffer.writeln('    if ($camelParam != null) {');
      buffer
          .writeln('      if (!params.containsKey("$wireName")) return false;');
      buffer.writeln('      final actual = params["$wireName"];');

      buffer.writeln('      if ($camelParam is Matcher) {');
      buffer.writeln(
          '        if (!$camelParam.matches(actual, {})) return false;');
      buffer.writeln('      } else {');

      if (param.usesGeneratedEnum) {
        final enumName =
            const EnumRenderer().buildEnumName(domainName, event, param);
        buffer.writeln('        if ($camelParam is $enumName) {');
        buffer.writeln(
            '          if (actual != $camelParam.value) return false;');
        buffer.writeln('        } else {');
        buffer.writeln('          if (actual != $camelParam) return false;');
        buffer.writeln('        }');
      } else if (param.dartType != null) {
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
