import 'package:analytics_gen/src/core/exceptions.dart';
import 'package:analytics_gen/src/parser/event_loader.dart';
import 'package:analytics_gen/src/parser/yaml_parser.dart';
import 'package:test/test.dart';

void main() {
  group('DomainParser dual_write_to', () {
    test('throws when dual_write_to is not a list', () async {
      final yaml = '''
auth:
  login:
    description: Test
    parameters:
      id: string
    dual_write_to: not_a_list
''';

      final parser = YamlParser();
      final source = AnalyticsSource(filePath: 'test.yaml', content: yaml);

      expect(
        () async => await parser.parseEvents([source]),
        throwsA(isA<AnalyticsAggregateException>().having(
          (e) => e.errors.first.message,
          'message',
          contains('Field "dual_write_to" must be a list of strings.'),
        )),
      );
    });

    test('parses dual_write_to as list of strings', () async {
      final yaml = '''
auth:
  login:
    description: Test
    parameters:
      id: string
    dual_write_to: [auth.secondary, tracking.track]
''';

      final parser = YamlParser();
      final source = AnalyticsSource(filePath: 'test.yaml', content: yaml);

      final domains = await parser.parseEvents([source]);

      final auth = domains['auth'];
      expect(auth, isNotNull);
      final event = auth!.events.firstWhere((e) => e.name == 'login');
      expect(event.dualWriteTo, ['auth.secondary', 'tracking.track']);
    });
  });
}
