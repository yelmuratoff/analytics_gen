import 'package:analytics_gen/src/core/exceptions.dart';
import 'package:analytics_gen/src/parser/event_loader.dart';
import 'package:analytics_gen/src/parser/yaml_parser.dart';
import 'package:test/test.dart';

void main() {
  group('YamlParser SourceSpan & Strict Validation', () {
    final parser = YamlParser();

    test('throws exception with span when root is not a map', () async {
      final source = AnalyticsSource(
        filePath: 'test.yaml',
        content: '["just", "a", "list"]',
      );

      try {
        await parser.parseEvents([source]);
        fail('Should have thrown AnalyticsAggregateException');
      } on AnalyticsAggregateException catch (e) {
        final error = e.errors.first;
        expect(error.message, contains('Root of the YAML file must be a map'));
        expect(error.span, isNotNull);
        expect(error.span!.start.line, 0);
      }
    });

    test('names the file in the message of a span-based error', () async {
      final source = AnalyticsSource(
        filePath: 'events/auth.yaml',
        content: 'auth:\n  login:\n    description: 42\n',
      );

      await expectLater(
        parser.parseEvents([source]),
        throwsA(
          isA<AnalyticsAggregateException>().having(
            (e) => e.errors.single.toString(),
            'error',
            contains('line 3, column 18 of events/auth.yaml'),
          ),
        ),
      );
    });

    test('reports a YAML syntax error once, at its location', () async {
      final source = AnalyticsSource(
        filePath: 'events/auth.yaml',
        content: 'auth:\n  login:\n    description: [unclosed\n',
      );

      await expectLater(
        parser.parseEvents([source]),
        throwsA(
          isA<AnalyticsAggregateException>().having(
            (e) => e.errors.single,
            'error',
            isA<AnalyticsParseException>()
                .having(
                  (e) => e.message,
                  'message',
                  "Invalid YAML: While parsing a flow sequence, expected ',' "
                      "or ']'.",
                )
                .having(
                  (e) => e.span?.sourceUrl?.path,
                  'span file',
                  'events/auth.yaml',
                ),
          ),
        ),
      );
    });

    test('names the file of a syntax error in a shared parameters file', () {
      expect(
        () => parser.parseSharedParameters(
          AnalyticsSource(filePath: 'shared.yaml', content: 'parameters: ['),
        ),
        throwsA(
          isA<AnalyticsParseException>().having(
            (e) => e.span?.sourceUrl?.path,
            'span file',
            'shared.yaml',
          ),
        ),
      );
    });

    test('names the file of a syntax error in a context file', () async {
      await expectLater(
        parser.parseContexts([
          AnalyticsSource(filePath: 'context.yaml', content: 'user: ['),
        ]),
        throwsA(
          isA<AnalyticsParseException>().having(
            (e) => e.span?.sourceUrl?.path,
            'span file',
            'context.yaml',
          ),
        ),
      );
    });

    test('throws exception when event definition is invalid', () async {
      final source = AnalyticsSource(
        filePath: 'test.yaml',
        content: '''
auth:
  user_login: "this should be a map, not a string"
''',
      );

      try {
        await parser.parseEvents([source]);
        fail('Should have thrown AnalyticsAggregateException');
      } on AnalyticsAggregateException catch (e) {
        final error = e.errors.first;
        expect(error.message, contains('must be a map'));
        expect(error.span, isNotNull);
        expect(error.span!.start.line, 1); // Line 1 is where "user_login" is
      }
    });

    test('throws exception for interpolated event names', () async {
      final source = AnalyticsSource(
        filePath: 'test.yaml',
        content: '''
auth:
  user_clicked_{button_id}: 
    parameters: []
''',
      );

      try {
        await parser.parseEvents([source]);
        fail('Should have thrown AnalyticsAggregateException');
      } on AnalyticsAggregateException catch (e) {
        final error = e.errors.first;
        expect(error.message, contains('interpolation characters'));
        expect(error.span, isNotNull);
        expect(error.span!.start.line, 1);
      }
    });

    test('throws exception for invalid parameter structure', () async {
      final source = AnalyticsSource(
        filePath: 'test.yaml',
        content: '''
auth:
  login:
    parameters:
      method:
        allowed_values: "not a list"
''',
      );

      try {
        await parser.parseEvents([source]);
        fail('Should have thrown AnalyticsAggregateException');
      } on AnalyticsAggregateException catch (e) {
        final error = e.errors.first;
        expect(error.message, contains('must be a list'));
        expect(error.span, isNotNull);
        expect(error.span!.start.line, 4);
      }
    });
  });
}
