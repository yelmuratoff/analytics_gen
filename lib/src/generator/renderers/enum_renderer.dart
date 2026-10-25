import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';

import '../../core/exceptions.dart';
import '../../models/analytics_event.dart';
import '../../util/string_utils.dart';

/// Renders Dart enums for analytics parameters with allowed values.
class EnumRenderer {
  /// Creates a new enum renderer.
  const EnumRenderer();

  /// Renders all enums for a given domain.
  String renderEnums(String domainName, AnalyticsDomain domain) {
    final buffer = StringBuffer();
    for (final event in domain.events) {
      for (final param in event.parameters) {
        if (param.type == 'string' &&
            param.allowedValues != null &&
            param.allowedValues!.isNotEmpty) {
          buffer.write(_renderEnum(domainName, event, param));
        }
      }
    }
    return buffer.toString();
  }

  String _renderEnum(
    String domainName,
    AnalyticsEvent event,
    AnalyticsParameter param,
  ) {
    final enumName = buildEnumName(domainName, event, param);
    final buffer = StringBuffer();

    buffer.writeln('/// Enum for ${event.name} - ${param.name}');
    buffer.writeln('enum $enumName {');

    final values = param.allowedValues!;
    final valuesByIdentifier = <String, String>{};
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      final stringValue = value.toString();
      final identifier = toEnumIdentifier(stringValue);

      final clashingValue = valuesByIdentifier[identifier];
      if (clashingValue != null) {
        throw AnalyticsGenerationException(
          'Allowed values "$clashingValue" and "$stringValue" of parameter '
          '"${param.name}" in $domainName.${event.name} map to the same enum '
          'constant "$identifier". Rename one of the values.',
          sourcePath: event.sourcePath,
          lineNumber: event.lineNumber,
        );
      }
      valuesByIdentifier[identifier] = stringValue;

      buffer.write(
        "  $identifier('${StringUtils.escapeSingleQuoted(stringValue)}')",
      );
      if (i == values.length - 1) {
        buffer.writeln(';');
      } else {
        buffer.writeln(',');
      }
    }

    buffer.writeln();
    buffer.writeln('  final String value;');
    buffer.writeln('  const $enumName(this.value);');
    buffer.writeln('}');
    buffer.writeln();

    return buffer.toString();
  }

  /// Builds the unique name for an enum based on domain, event, and parameter.
  String buildEnumName(
    String domainName,
    AnalyticsEvent event,
    AnalyticsParameter param,
  ) {
    return 'Analytics${StringUtils.capitalizePascal(domainName)}${StringUtils.capitalizePascal(event.name)}${StringUtils.capitalizePascal(param.codeName)}Enum';
  }

  /// Converts a string value to a valid Dart enum identifier.
  ///
  /// Handles reserved words (e.g. `continue` → `valueContinue`) and
  /// digit-prefixed identifiers (e.g. `123test` → `value123test`).
  /// Any character other than an ASCII letter or digit separates words
  /// (e.g. `Credit Card` → `creditCard`).
  String toEnumIdentifier(String value) {
    final words = value
        .split(RegExp('[^A-Za-z0-9]+'))
        .where((word) => word.isNotEmpty)
        .join('_');
    final camel = StringUtils.toCamelCase(words);
    if (camel.isEmpty) return 'empty';
    if (StringUtils.dartReservedWords.contains(camel)) {
      return 'value${camel[0].toUpperCase()}${camel.substring(1)}';
    }
    if (RegExp(r'^[0-9]').hasMatch(camel)) {
      return 'value$camel';
    }
    return camel;
  }
}
