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
}
