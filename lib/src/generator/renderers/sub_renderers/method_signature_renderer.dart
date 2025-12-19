import 'package:analytics_gen/src/models/analytics_event.dart';

import '../../../util/string_utils.dart';
import '../../../util/type_mapper.dart';
import '../enum_renderer.dart';

/// Renders method signatures.
class MethodSignatureRenderer {
  /// Creates a new method signature renderer.
  const MethodSignatureRenderer();

  /// Renders the full parameter list string (e.g. `{required String id, int? val}`)
  String renderParameters(
    String domainName,
    AnalyticsEvent event, {
    int indent = 0,
  }) {
    final buffer = StringBuffer();
    final indentStr = '  ' * indent;

    if (event.parameters.isNotEmpty) {
      buffer.writeln('{');
      for (final param in event.parameters) {
        final isEnum = param.type == 'string' &&
            param.allowedValues != null &&
            param.allowedValues!.isNotEmpty;

        String dartType;
        if (param.dartType != null) {
          dartType = param.dartType!;
        } else if (isEnum) {
          dartType =
              const EnumRenderer().buildEnumName(domainName, event, param);
        } else {
          dartType = DartTypeMapper.toDartType(param.type);
        }

        final nullableType = param.isNullable ? '$dartType?' : dartType;
        final required = param.isNullable ? '' : 'required ';
        final camelParam = StringUtils.toCamelCase(param.codeName);
        buffer.writeln('$indentStr  $required$nullableType $camelParam,');
      }

      // Add optional parameters override
      final hasParametersParam = event.parameters
          .any((p) => StringUtils.toCamelCase(p.codeName) == 'parameters');
      final parametersArgName =
          hasParametersParam ? 'analyticsParameters' : 'parameters';
      buffer.writeln('$indentStr  Map<String, Object?>? $parametersArgName,');

      buffer.write('$indentStr}');
    } else {
      // Add optional parameters override even if no params
      buffer.write('{Map<String, Object?>? parameters}');
    }

    return buffer.toString();
  }

  /// Alias for [renderParameters].
  String renderEventArguments(
    String domainName,
    AnalyticsEvent event, {
    int indent = 0,
  }) =>
      renderParameters(domainName, event, indent: indent);
}
