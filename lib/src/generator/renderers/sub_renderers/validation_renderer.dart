import '../../../util/string_utils.dart';

/// Renders validation checks for parameters.
class ValidationRenderer {
  /// Creates a new validation renderer.
  const ValidationRenderer();

  /// Renders an allowed values validation check.
  String renderAllowedValuesCheck({
    required String camelParam,
    required String constName,
    required String encodedValues,
    required String joinedValues,
    required bool isNullable,
    required String type,
    int indent = 0,
  }) {
    final indentStr = '  ' * indent;
    final buffer = StringBuffer();

    // Strip nullable suffix for the Set type definition
    final setType =
        type.endsWith('?') ? type.substring(0, type.length - 1) : type;

    buffer.writeln(
      '$indentStr    const $constName = <$setType>{$encodedValues};',
    );

    final condition = isNullable
        ? 'if ($camelParam != null && !$constName.contains($camelParam)) {'
        : 'if (!$constName.contains($camelParam)) {';

    buffer.writeln('$indentStr    $condition');
    buffer.writeln('$indentStr      throw ArgumentError.value(');
    buffer.writeln('$indentStr        $camelParam,');
    buffer.writeln("$indentStr        '$camelParam',");
    buffer.writeln("$indentStr        'must be one of $joinedValues',");
    buffer.writeln('$indentStr      );');
    buffer.writeln('$indentStr    }');

    return buffer.toString();
  }

  /// Renders validation checks for parameters (regex, length, range).
  ///
  /// If [cachedRegexFieldName] is provided, the regex validation will use
  /// a static field reference instead of creating a new RegExp instance.
  String renderValidationChecks({
    required String camelParam,
    required bool isNullable,
    String? regex,
    int? minLength,
    int? maxLength,
    num? min,
    num? max,
    int indent = 0,
    String? cachedRegexFieldName,
  }) {
    final indentStr = '  ' * indent;
    final buffer = StringBuffer();

    // Regex validation
    if (regex != null) {
      // Prefer cached regex when available (compiled once at mixin level).
      // Otherwise, declare a local final to keep generated code readable and
      // avoid repeating the regex literal in the condition.
      final regexRef = cachedRegexFieldName ?? '_${camelParam}Regex';

      if (cachedRegexFieldName == null) {
        buffer.writeln(
          "$indentStr    final $regexRef = RegExp(r'$regex');",
        );
      }

      final condition = isNullable
          ? 'if ($camelParam != null && !$regexRef.hasMatch($camelParam)) {'
          : 'if (!$regexRef.hasMatch($camelParam)) {';
      buffer.writeln('$indentStr    $condition');
      buffer.writeln('$indentStr      throw ArgumentError.value(');
      buffer.writeln('$indentStr        $camelParam,');
      buffer.writeln("$indentStr        '$camelParam',");
      buffer.writeln(
          "$indentStr        'must match regex ${StringUtils.escapeSingleQuoted(regex)}',");
      buffer.writeln('$indentStr      );');
      buffer.writeln('$indentStr    }');
    }

    // Length validation (String)
    if (minLength != null || maxLength != null) {
      final lengthCheck = StringBuffer();
      if (minLength != null) {
        lengthCheck.write('$camelParam.length < $minLength');
      }
      if (minLength != null && maxLength != null) lengthCheck.write(' || ');
      if (maxLength != null) {
        lengthCheck.write('$camelParam.length > $maxLength');
      }

      final condition = isNullable
          ? 'if ($camelParam != null && (${lengthCheck.toString()})) {'
          : 'if (${lengthCheck.toString()}) {';

      buffer.writeln('$indentStr    $condition');
      buffer.writeln('$indentStr      throw ArgumentError.value(');
      buffer.writeln('$indentStr        $camelParam,');
      buffer.writeln("$indentStr        '$camelParam',");
      final msg = minLength != null && maxLength != null
          ? 'length must be between $minLength and $maxLength'
          : minLength != null
              ? 'length must be at least $minLength'
              : 'length must be at most $maxLength';
      buffer.writeln("$indentStr        '$msg',");
      buffer.writeln('$indentStr      );');
      buffer.writeln('$indentStr    }');
    }

    // Range validation (num)
    if (min != null || max != null) {
      final rangeCheck = StringBuffer();
      if (min != null) rangeCheck.write('$camelParam < $min');
      if (min != null && max != null) rangeCheck.write(' || ');
      if (max != null) rangeCheck.write('$camelParam > $max');

      final condition = isNullable
          ? 'if ($camelParam != null && (${rangeCheck.toString()})) {'
          : 'if (${rangeCheck.toString()}) {';

      buffer.writeln('$indentStr    $condition');
      buffer.writeln('$indentStr      throw ArgumentError.value(');
      buffer.writeln('$indentStr        $camelParam,');
      buffer.writeln("$indentStr        '$camelParam',");
      final msg = min != null && max != null
          ? 'must be between $min and $max'
          : min != null
              ? 'must be at least $min'
              : 'must be at most $max';
      buffer.writeln("$indentStr        '$msg',");
      buffer.writeln('$indentStr      );');
      buffer.writeln('$indentStr    }');
    }

    return buffer.toString();
  }

  /// Escapes and encodes a list of allowed values for code generation.
  String encodeAllowedValues(List<dynamic> values) {
    return values.map((value) {
      if (value is String) {
        return "'${StringUtils.escapeSingleQuoted(value)}'";
      }
      return value.toString();
    }).join(', ');
  }

  /// Joins allowed values for error messages.
  String joinAllowedValues(List<dynamic> values) {
    return values.join(', ');
  }
}
