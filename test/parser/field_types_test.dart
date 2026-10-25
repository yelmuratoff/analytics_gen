import 'package:analytics_gen/src/core/exceptions.dart';
import 'package:analytics_gen/src/parser/event_loader.dart';
import 'package:analytics_gen/src/parser/yaml_parser.dart';
import 'package:test/test.dart';

void main() {
  group('mistyped fields', () {
    TypeMatcher<AnalyticsParseException> rejects(
      String field,
      String expected,
      String valueText,
    ) {
      return isA<AnalyticsParseException>()
          .having(
            (e) => e.message,
            'message',
            'Field "$field" must be $expected.',
          )
          .having((e) => e.span?.text, 'span text', valueText);
    }

    const eventFields = {
      'description': ('42', 'a string'),
      'event_name': ('7', 'a string'),
      'identifier': ('7', 'a string'),
      'deprecated': ('"yes"', 'true or false'),
      'replacement': ('7', 'a string'),
      'added_in': ('1.2', 'a string'),
      'deprecated_in': ('2', 'a string'),
    };

    for (final MapEntry(key: field, value: (value, expected))
        in eventFields.entries) {
      test('reports event field $field at its value', () async {
        final parsing = YamlParser().parseEvents([
          AnalyticsSource(
            filePath: 'events.yaml',
            content: 'app:\n'
                '  opened:\n'
                '    $field: $value\n',
          ),
        ]);

        await expectLater(
          parsing,
          throwsA(
            isA<AnalyticsAggregateException>().having(
              (e) => e.errors.single,
              'error',
              rejects(field, expected, value),
            ),
          ),
        );
      });
    }

    const parameterFields = {
      'description': ('42', 'a string'),
      'identifier': ('7', 'a string'),
      'param_name': ('7', 'a string'),
      'added_in': ('1.2', 'a string'),
      'deprecated_in': ('2', 'a string'),
      'dart_type': ('7', 'a string'),
      'import': ('7', 'a string'),
      'regex': ('7', 'a string'),
      'min_length': ('1.5', 'an integer'),
      'max_length': ('"5"', 'an integer'),
    };

    for (final MapEntry(key: field, value: (value, expected))
        in parameterFields.entries) {
      test('reports parameter field $field at its value', () async {
        final parsing = YamlParser().parseEvents([
          AnalyticsSource(
            filePath: 'events.yaml',
            content: 'app:\n'
                '  opened:\n'
                '    description: Test\n'
                '    parameters:\n'
                '      field:\n'
                '        type: string\n'
                '        $field: $value\n',
          ),
        ]);

        await expectLater(
          parsing,
          throwsA(
            isA<AnalyticsAggregateException>().having(
              (e) => e.errors.single,
              'error',
              rejects(field, expected, value),
            ),
          ),
        );
      });
    }

    for (final field in ['min', 'max']) {
      test('reports parameter field $field when it is not a number', () async {
        final parsing = YamlParser().parseEvents([
          AnalyticsSource(
            filePath: 'events.yaml',
            content: 'app:\n'
                '  opened:\n'
                '    description: Test\n'
                '    parameters:\n'
                '      count:\n'
                '        type: int\n'
                '        $field: "1"\n',
          ),
        ]);

        await expectLater(
          parsing,
          throwsA(
            isA<AnalyticsAggregateException>().having(
              (e) => e.errors.single,
              'error',
              rejects(field, 'a number', '"1"'),
            ),
          ),
        );
      });
    }

    test('reports a mistyped context property field with its file', () async {
      final parsing = YamlParser().parseContexts([
        AnalyticsSource(
          filePath: 'contexts/profile.yaml',
          content: 'profile:\n'
              '  nickname:\n'
              '    type: string\n'
              '    description: 42\n',
        ),
      ]);

      await expectLater(
        parsing,
        throwsA(
          rejects('description', 'a string', '42').having(
            (e) => e.filePath,
            'filePath',
            'contexts/profile.yaml',
          ),
        ),
      );
    });

    test('reports a mistyped shared parameter field', () {
      expect(
        () => YamlParser().parseSharedParameters(
          AnalyticsSource(
            filePath: 'shared.yaml',
            content: 'parameters:\n'
                '  user_id:\n'
                '    type: string\n'
                '    description: 42\n',
          ),
        ),
        throwsA(rejects('description', 'a string', '42')),
      );
    });
  });
}
