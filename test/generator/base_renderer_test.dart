import 'package:analytics_gen/src/generator/renderers/base_renderer.dart';
import 'package:analytics_gen/src/generator/renderers/sub_renderers/validation_renderer.dart';
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
      expect(
        header,
        contains(
          '// ignore_for_file: type=lint, unused_import, deprecated_member_use_from_same_package',
        ),
      );
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

    test('renderClassHeader generates plain class declaration', () {
      final header = renderer.renderClassHeader(
        className: 'TestClass',
      );

      expect(header, contains('class TestClass {'));
    });
  });

  group('ValidationRenderer', () {
    const validator = ValidationRenderer();

    test('renderAllowedValuesCheck generates validation for non-nullable', () {
      final check = validator.renderAllowedValuesCheck(
        camelParam: 'method',
        constName: 'allowedMethodValues',
        encodedValues: "'email', 'google'",
        joinedValues: 'email, google',
        isNullable: false,
        type: 'String',
      );

      expect(check, contains('const allowedMethodValues = <String>{'));
      expect(check, contains("'email', 'google'"));
      expect(check, contains('if (!allowedMethodValues.contains(method))'));
      expect(check, contains('throw ArgumentError.value'));
      expect(check, contains('must be one of email, google'));
    });

    test('renderAllowedValuesCheck generates validation for nullable', () {
      final check = validator.renderAllowedValuesCheck(
        camelParam: 'method',
        constName: 'allowedMethodValues',
        encodedValues: "'email', 'google'",
        joinedValues: 'email, google',
        isNullable: true,
        type: 'String',
      );

      expect(
          check,
          contains(
              'if (method != null && !allowedMethodValues.contains(method))'));
    });

    test('encodeAllowedValues escapes and joins values', () {
      final encoded =
          validator.encodeAllowedValues(['email', "test's value", 'google']);

      expect(encoded, equals("'email', 'test\\'s value', 'google'"));
    });

    test('joinAllowedValues joins with comma and space', () {
      final joined = validator.joinAllowedValues(['email', 'google', 'apple']);

      expect(joined, equals('email, google, apple'));
    });

    test('renderValidationChecks generates regex validation for non-nullable',
        () {
      final checks = validator.renderValidationChecks(
        camelParam: 'email',
        isNullable: false,
        regex: r'^[^@]+@[^@]+\.[^@]+$',
      );

      // Without cachedRegexFieldName, creates inline local variable
      expect(checks,
          contains("final _emailRegex = RegExp(r'^[^@]+@[^@]+\\.[^@]+\$');"));
      expect(checks, contains('if (!_emailRegex.hasMatch(email))'));
      expect(checks, contains('throw ArgumentError.value'));
      expect(checks, contains('must match regex'));
    });

    test('renderValidationChecks generates regex validation for nullable', () {
      final checks = validator.renderValidationChecks(
        camelParam: 'email',
        isNullable: true,
        regex: r'^[^@]+@[^@]+\.[^@]+$',
      );

      // Without cachedRegexFieldName, creates inline local variable
      expect(checks,
          contains("final _emailRegex = RegExp(r'^[^@]+@[^@]+\\.[^@]+\$');"));
      expect(checks,
          contains('if (email != null && !_emailRegex.hasMatch(email))'));
    });

    test('renderValidationChecks uses cached regex field when provided', () {
      final checks = validator.renderValidationChecks(
        camelParam: 'email',
        isNullable: false,
        regex: r'^[^@]+@[^@]+\.[^@]+$',
        cachedRegexFieldName: '_emailRegex',
      );

      // Uses the cached static field directly
      expect(checks, isNot(contains('final _emailRegex')));
      expect(checks, contains('if (!_emailRegex.hasMatch(email))'));
    });

    test(
        'renderValidationChecks generates length validation for non-nullable with min and max',
        () {
      final checks = validator.renderValidationChecks(
        camelParam: 'name',
        isNullable: false,
        minLength: 2,
        maxLength: 50,
      );

      expect(checks, contains('if (name.length < 2 || name.length > 50)'));
      expect(checks, contains('length must be between 2 and 50'));
    });

    test(
        'renderValidationChecks generates length validation for nullable with max only',
        () {
      final checks = validator.renderValidationChecks(
        camelParam: 'description',
        isNullable: true,
        maxLength: 100,
      );

      expect(checks,
          contains('if (description != null && (description.length > 100))'));
      expect(checks, contains('length must be at most 100'));
    });

    test(
        'renderValidationChecks generates length validation for non-nullable with min only',
        () {
      final checks = validator.renderValidationChecks(
        camelParam: 'code',
        isNullable: false,
        minLength: 5,
      );

      expect(checks, contains('if (code.length < 5)'));
      expect(checks, contains('length must be at least 5'));
    });

    test(
        'renderValidationChecks generates range validation for non-nullable with min and max',
        () {
      final checks = validator.renderValidationChecks(
        camelParam: 'age',
        isNullable: false,
        min: 0,
        max: 120,
      );

      expect(checks, contains('if (age < 0 || age > 120)'));
      expect(checks, contains('must be between 0 and 120'));
    });

    test(
        'renderValidationChecks generates range validation for nullable with max only',
        () {
      final checks = validator.renderValidationChecks(
        camelParam: 'score',
        isNullable: true,
        max: 100,
      );

      expect(checks, contains('if (score != null && (score > 100))'));
      expect(checks, contains('must be at most 100'));
    });

    test(
        'renderValidationChecks generates range validation for non-nullable with min only',
        () {
      final checks = validator.renderValidationChecks(
        camelParam: 'temperature',
        isNullable: false,
        min: -50,
      );

      expect(checks, contains('if (temperature < -50)'));
      expect(checks, contains('must be at least -50'));
    });

    test('encodeAllowedValues handles non-string values', () {
      final encoded = validator.encodeAllowedValues([1, 2.5, true]);

      expect(encoded, equals('1, 2.5, true'));
    });
  });
}

class _TestRenderer extends BaseRenderer {
  const _TestRenderer();
}
