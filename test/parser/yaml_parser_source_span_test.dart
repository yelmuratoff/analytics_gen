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
