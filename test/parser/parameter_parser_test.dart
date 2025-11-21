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

    test('parses validation rules', () {
      final yaml = loadYaml('''
        username:
          type: String
          regex: "^[a-z]+\$"
          min_length: 3
          max_length: 20
        age:
          type: int
          min: 18
          max: 100
      ''') as YamlMap;

      final params = parser.parseParameters(
        yaml,
        domainName: 'test',
        eventName: 'event',
        filePath: 'test.yaml',
      );

      expect(params, hasLength(2));

      final age = params.firstWhere((p) => p.name == 'age');
      expect(age.min, 18);
      expect(age.max, 100);

      final username = params.firstWhere((p) => p.name == 'username');
      expect(username.regex, '^[a-z]+\$');
      expect(username.minLength, 3);
      expect(username.maxLength, 20);
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

    test('throws on empty identifier', () {
      final yaml = loadYaml('''
        param:
          type: String
          identifier: ""
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
          contains('must declare a non-empty identifier'),
        )),
      );
    });

    test('throws on duplicate analytics parameter names', () {
      final yaml = loadYaml('''
        param1:
          type: String
          param_name: duplicate_name
        param2:
          type: int
          param_name: duplicate_name
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
          contains('Duplicate analytics parameter "duplicate_name" found'),
        )),
      );
    });

    test('throws on operations not being a list', () {
      final yaml = loadYaml('''
        param:
          type: String
          operations: "not_a_list"
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
          contains('operations for parameter "param" must be a list'),
        )),
      );
    });

    test('throws on meta field not being a map', () {
      final yaml = loadYaml('''
        param:
          type: String
          meta: "not_a_map"
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
          contains('The "meta" field must be a map'),
        )),
      );
    });

    test('parses operations as list of strings', () {
      final yaml = loadYaml('''
        param:
          type: String
          operations:
            - add
            - remove
            - update
      ''') as YamlMap;

      final params = parser.parseParameters(
        yaml,
        domainName: 'test',
        eventName: 'event',
        filePath: 'test.yaml',
      );

      expect(params, hasLength(1));
      final param = params.first;
      expect(param.operations, ['add', 'remove', 'update']);
    });
  });
}