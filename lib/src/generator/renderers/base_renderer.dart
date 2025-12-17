import '../utils/code_buffer.dart';

/// Base class for all renderers to reduce code duplication.
///
/// Provides common functionality for generating file headers,
/// imports, documentation comments, and validation checks.
abstract class BaseRenderer {
  /// Creates a new base renderer.
  const BaseRenderer();

  /// Renders a standard file header for generated files.
  ///
  /// Includes GENERATED CODE warning, generator version, and common ignore directives.
  /// The version helps developers know if regeneration is needed after package updates.
  String renderFileHeader({bool includeCoverageIgnore = true}) {
    final buffer = StringBuffer();
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');

    buffer.writeln(
      '// ignore_for_file: type=lint, unused_import, deprecated_member_use_from_same_package',
    );
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

    final buffer = CodeBuffer(initialIndent: indent);
    final lines = comment.split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) {
        buffer.writeln('///');
      } else {
        buffer.writeln('/// $line');
      }
    }

    return buffer.toString();
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
