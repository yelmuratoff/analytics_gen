import 'package:analytics_gen/src/generator/renderers/base_renderer.dart';
import 'package:test/test.dart';

void main() {
  group('BaseRenderer', () {
    late _TestRenderer renderer;

    setUp(() {
      renderer = _TestRenderer();
    });

    test('renderFileHeader generates standard header with coverage ignore', () {
      final header = renderer.renderFileHeader();

      expect(header, contains('// GENERATED CODE - DO NOT MODIFY BY HAND'));
      expect(header, contains('// ignore_for_file: type=lint, unused_import'));
      expect(
          header,
          contains(
              '// ignore_for_file: directives_ordering, unnecessary_string_interpolations'));
      expect(header, contains('// coverage:ignore-file'));
    });

    test('renderFileHeader can exclude coverage ignore', () {
      final header = renderer.renderFileHeader(includeCoverageIgnore: false);

      expect(header, contains('// GENERATED CODE - DO NOT MODIFY BY HAND'));
      expect(header, isNot(contains('// coverage:ignore-file')));
    });

    test('renderImports generates import statements', () {
      final imports = renderer.renderImports([
        'package:analytics_gen/analytics_gen.dart',
        'dart:io',
        '../models/event.dart',
      ]);

      expect(imports,
          contains("import 'package:analytics_gen/analytics_gen.dart';"));
      expect(imports, contains("import 'dart:io';"));
      expect(imports, contains("import '../models/event.dart';"));
    });

    test('renderImports returns empty string for empty list', () {
      final imports = renderer.renderImports([]);
      expect(imports, isEmpty);
    });

    test('renderDocComment formats single-line comment', () {
      final comment = renderer.renderDocComment('This is a test');

      expect(comment, equals('/// This is a test\n'));
    });

    test('renderDocComment formats multi-line comment', () {
      final comment =
          renderer.renderDocComment('Line 1\nLine 2\n\nLine 3', indent: 0);

      expect(comment, contains('/// Line 1'));
      expect(comment, contains('/// Line 2'));
      expect(comment, contains('///\n'));
      expect(comment, contains('/// Line 3'));
    });

    test('renderDocComment applies indentation', () {
      final comment = renderer.renderDocComment('Test', indent: 2);

      expect(comment, equals('    /// Test\n'));
    });

    test('renderAllowedValuesCheck generates validation for non-nullable', () {
      final check = renderer.renderAllowedValuesCheck(
        camelParam: 'method',
        constName: 'allowedMethodValues',
        encodedValues: "'email', 'google'",
        joinedValues: 'email, google',
        isNullable: false,
      );

      expect(check, contains('const allowedMethodValues = <String>{'));
      expect(check, contains("'email', 'google'"));
      expect(check, contains('if (!allowedMethodValues.contains(method))'));
      expect(check, contains('throw ArgumentError.value'));
      expect(check, contains('must be one of email, google'));
    });

    test('renderAllowedValuesCheck generates validation for nullable', () {
      final check = renderer.renderAllowedValuesCheck(
        camelParam: 'method',
        constName: 'allowedMethodValues',
        encodedValues: "'email', 'google'",
        joinedValues: 'email, google',
        isNullable: true,
      );

      expect(
          check,
          contains(
              'if (method != null && !allowedMethodValues.contains(method))'));
    });

    test('encodeAllowedValues escapes and joins values', () {
      final encoded =
          renderer.encodeAllowedValues(['email', "test's value", 'google']);

      expect(encoded, equals("'email', 'test\\'s value', 'google'"));
    });

    test('joinAllowedValues joins with comma and space', () {
      final joined = renderer.joinAllowedValues(['email', 'google', 'apple']);

      expect(joined, equals('email, google, apple'));
    });

    test('renderClassHeader generates mixin declaration', () {
      final header = renderer.renderClassHeader(
        className: 'TestMixin',
        extendsClass: 'BaseClass',
        isMixin: true,
        documentation: 'Test mixin documentation',
      );

      expect(header, contains('/// Test mixin documentation'));
      expect(header, contains('mixin TestMixin on BaseClass {'));
    });

    test('renderClassHeader generates final class declaration', () {
      final header = renderer.renderClassHeader(
        className: 'TestClass',
        extendsClass: 'BaseClass',
        mixins: ['Mixin1', 'Mixin2'],
        implements: ['Interface1'],
        isFinal: true,
      );

      expect(header, contains('final class TestClass extends BaseClass'));
      expect(header, contains('with Mixin1, Mixin2'));
      expect(header, contains('implements Interface1'));
    });

    test('renderMethodParameters generates named parameters', () {
      final params = renderer.renderMethodParameters(
        parameters: [
          const MethodParameter(name: 'name', type: 'String'),
          const MethodParameter(name: 'age', type: 'int?', isNullable: true),
          const MethodParameter(
            name: 'status',
            type: 'String?',
            defaultValue: "'active'",
            isNullable: true,
          ),
        ],
      );

      expect(params, contains('required String name'));
      expect(params, contains('int? age'));
      expect(params, contains("String? status = 'active'"));
      expect(params, startsWith('({'));
      expect(params, endsWith('})'));
    });

    test('renderMethodParameters generates positional parameters', () {
      final params = renderer.renderMethodParameters(
        parameters: [
          const MethodParameter(name: 'name', type: 'String'),
          const MethodParameter(name: 'age', type: 'int', defaultValue: '0'),
        ],
        useNamedParameters: false,
      );

      expect(params, contains('String name'));
      expect(params, contains('int age = 0'));
      expect(params, startsWith('('));
      expect(params, endsWith(')'));
      expect(params, isNot(contains('required')));
    });

    test('renderMethodParameters returns empty parens for no parameters', () {
      final params = renderer.renderMethodParameters(parameters: []);

      expect(params, equals('()'));
    });
  });
}

class _TestRenderer extends BaseRenderer {
  const _TestRenderer();
}
