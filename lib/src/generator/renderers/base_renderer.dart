import '../../util/string_utils.dart';

/// Base class for all renderers to reduce code duplication.
///
/// Provides common functionality for generating file headers,
/// imports, documentation comments, and validation checks.
abstract class BaseRenderer {
  /// Creates a new base renderer.
  const BaseRenderer();

  /// Renders a standard file header for generated files.
  ///
  /// Includes GENERATED CODE warning and common ignore directives.
  String renderFileHeader({bool includeCoverageIgnore = true}) {
    final buffer = StringBuffer();
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// ignore_for_file: type=lint, unused_import');
    if (includeCoverageIgnore) {
      buffer.writeln(
        '// ignore_for_file: directives_ordering, unnecessary_string_interpolations',
      );
      buffer.writeln('// coverage:ignore-file');
    }
    buffer.writeln();
    return buffer.toString();
  }

  /// Renders import statements.
  ///
  /// Takes a list of import paths and generates properly formatted
  /// import statements.
  String renderImports(List<String> imports) {
    if (imports.isEmpty) return '';

    final buffer = StringBuffer();
    for (final import in imports) {
      if (import.startsWith('package:')) {
        buffer.writeln("import '$import';");
      } else {
        buffer.writeln("import '$import';");
      }
    }
    buffer.writeln();
    return buffer.toString();
  }

  /// Renders a documentation comment block.
  ///
  /// Properly formats multi-line documentation with /// prefix.
  String renderDocComment(String comment, {int indent = 0}) {
    if (comment.isEmpty) return '';

    final indentStr = '  ' * indent;
    final buffer = StringBuffer();
    final lines = comment.split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) {
        buffer.writeln('$indentStr///');
      } else {
        buffer.writeln('$indentStr/// $line');
      }
    }

    return buffer.toString();
  }

  /// Renders an allowed values validation check.
  ///
  /// Generates runtime validation code for parameters with allowed_values.
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
  String renderValidationChecks({
    required String camelParam,
    required bool isNullable,
    String? regex,
    int? minLength,
    int? maxLength,
    num? min,
    num? max,
    int indent = 0,
  }) {
    final indentStr = '  ' * indent;
    final buffer = StringBuffer();

    // Regex validation
    if (regex != null) {
      final condition = isNullable
          ? 'if ($camelParam != null && !RegExp(r\'$regex\').hasMatch($camelParam)) {'
          : 'if (!RegExp(r\'$regex\').hasMatch($camelParam)) {';
      buffer.writeln('$indentStr    $condition');
      buffer.writeln('$indentStr      throw ArgumentError.value(');
      buffer.writeln('$indentStr        $camelParam,');
      buffer.writeln("$indentStr        '$camelParam',");
      buffer.writeln("$indentStr        'must match regex $regex',");
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
  ///
  /// Returns a comma-separated string of escaped values ready for code.
  String encodeAllowedValues(List<Object> values) {
    return values.map((value) {
      if (value is String) {
        return "'${StringUtils.escapeSingleQuoted(value)}'";
      }
      return value.toString();
    }).join(', ');
  }

  /// Joins allowed values for error messages.
  String joinAllowedValues(List<Object> values) {
    return values.join(', ');
  }

  /// Renders a class or mixin declaration header.
  String renderClassHeader({
    required String className,
    String? extendsClass,
    List<String> mixins = const [],
    List<String> implements = const [],
    bool isFinal = false,
    bool isMixin = false,
    String? documentation,
  }) {
    final buffer = StringBuffer();

    if (documentation != null && documentation.isNotEmpty) {
      buffer.write(renderDocComment(documentation));
    }

    if (isMixin) {
      buffer.write('mixin $className');
      if (extendsClass != null) {
        buffer.write(' on $extendsClass');
      }
    } else {
      if (isFinal) {
        buffer.write('final class $className');
      } else {
        buffer.write('class $className');
      }

      if (extendsClass != null) {
        buffer.write(' extends $extendsClass');
      }

      if (mixins.isNotEmpty) {
        buffer.write(' with ${mixins.join(', ')}');
      }
    }

    if (implements.isNotEmpty) {
      buffer.write(' implements ${implements.join(', ')}');
    }

    buffer.writeln(' {');

    return buffer.toString();
  }

  /// Renders method parameters.
  String renderMethodParameters({
    required List<MethodParameter> parameters,
    bool useNamedParameters = true,
  }) {
    if (parameters.isEmpty) return '()';

    final buffer = StringBuffer();

    if (useNamedParameters) {
      buffer.write('({');
      for (var i = 0; i < parameters.length; i++) {
        final param = parameters[i];
        if (i > 0) buffer.write(', ');

        if (!param.isNullable) {
          buffer.write('required ');
        }
        buffer.write('${param.type} ${param.name}');

        if (param.defaultValue != null) {
          buffer.write(' = ${param.defaultValue}');
        }
      }
      buffer.write('})');
    } else {
      buffer.write('(');
      for (var i = 0; i < parameters.length; i++) {
        final param = parameters[i];
        if (i > 0) buffer.write(', ');
        buffer.write('${param.type} ${param.name}');

        if (param.defaultValue != null) {
          buffer.write(' = ${param.defaultValue}');
        }
      }
      buffer.write(')');
    }

    return buffer.toString();
  }
}

/// Represents a method parameter for code generation.
class MethodParameter {
  /// Creates a new method parameter.
  const MethodParameter({
    required this.name,
    required this.type,
    this.isNullable = false,
    this.defaultValue,
    this.documentation,
  });

  /// The parameter name.
  final String name;

  /// The parameter type.
  final String type;

  /// Whether the parameter is nullable.
  final bool isNullable;

  /// The default value for the parameter, if any.
  final String? defaultValue;

  /// The documentation comment for the parameter, if any.
  final String? documentation;
}
