import 'package:analytics_gen/src/config/naming_strategy.dart';
import 'package:analytics_gen/src/core/exceptions.dart';
import 'package:analytics_gen/src/parser/parameter_parser.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('ParameterParser', () {
    late ParameterParser parser;

    setUp(() {
      parser = const ParameterParser(NamingStrategy());
    });

    test('parses simple parameters', () {
      final yaml = loadYaml('''
        user_id: String
        count: int
      ''') as YamlMap;

      final params = parser.parseParameters(
        yaml,
        domainName: 'test',
        eventName: 'event',
        filePath: 'test.yaml',
      );

      expect(params, hasLength(2));
      expect(params[0].name, 'count');
      expect(params[0].type, 'int');
      expect(params[1].name, 'user_id');
      expect(params[1].type, 'String');
    });

    test('parses complex parameters with description and meta', () {
      final yaml = loadYaml('''
        user_id:
          type: String
          description: The user ID
          meta:
            pii: true
      ''') as YamlMap;

      final params = parser.parseParameters(
        yaml,
        domainName: 'test',
        eventName: 'event',
        filePath: 'test.yaml',
      );

      expect(params, hasLength(1));
      final param = params.first;
      expect(param.name, 'user_id');
      expect(param.type, 'String');
      expect(param.description, 'The user ID');
      expect(param.meta, {'pii': true});
    });

    test('throws on duplicate parameters (camelCase conflict)', () {
      // Use a permissive strategy to allow camelCase identifiers so we can test conflict logic
      // without tripping over the snake_case validation first.
      final permissiveParser = const ParameterParser(NamingStrategy(
        enforceSnakeCaseParameters: false,
      ));

      final yamlConflict = loadYaml('''
        user_id: String
        user-id: int
      ''') as YamlMap;

      expect(
        () => permissiveParser.parseParameters(
          yamlConflict,
          domainName: 'test',
          eventName: 'event',
          filePath: 'test.yaml',
        ),
        throwsA(isA<AnalyticsParseException>().having(
          (e) => e.message,
          'message',
          contains('conflicts with "user-id" after camelCase normalization'),
        )),
      );
    });

    test('throws on invalid identifier', () {
      final yaml = loadYaml('''
        123invalid: String
      ''') as YamlMap;

      expect(
        () => parser.parseParameters(
          yaml,
          domainName: 'test',
          eventName: 'event',
          filePath: 'test.yaml',
        ),
        throwsA(isA<AnalyticsParseException>().having(
          (e) => e.message,
          'message',
          contains('violates the configured naming strategy'),
        )),
      );
    });
  });
}
