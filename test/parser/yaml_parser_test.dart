import 'dart:io';

import 'package:analytics_gen/src/config/naming_strategy.dart';
import 'package:analytics_gen/src/core/exceptions.dart';
import 'package:analytics_gen/src/parser/yaml_parser.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

// Helper type used in tests to create map keys that stringify to the same
// value while remaining distinct map keys (Dart object identity).
class KeyWithToString {
  final String id;
  KeyWithToString(this.id);

  @override
  String toString() => 'dup';
}

void main() {
  group('YamlParser', () {
    late Directory tempDir;
    late String eventsPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('analytics_gen_test_');
      eventsPath = tempDir.path;
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('parses simple event without parameters', () async {
      final yamlFile = File(path.join(eventsPath, 'auth.yaml'));
      await yamlFile.writeAsString(
          'auth:\n  logout:\n    description: User logs out\n    parameters: {}\n');

      final parser = YamlParser(eventsPath: eventsPath);
      final domains = await parser.parseEvents();

      expect(domains.length, equals(1));
      expect(domains.containsKey('auth'), isTrue);

      final authDomain = domains['auth']!;
      expect(authDomain.events.length, equals(1));

      final logoutEvent = authDomain.events.first;
      expect(logoutEvent.name, equals('logout'));
      expect(logoutEvent.description, equals('User logs out'));
      expect(logoutEvent.parameters, isEmpty);
    });

    test('parses event with simple parameters', () async {
      final yamlFile = File(path.join(eventsPath, 'auth.yaml'));
      await yamlFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: User logs in\n'
        '    deprecated: true\n'
        '    replacement: auth.login_v2\n'
        '    parameters:\n'
        '      method: string\n'
        '      user_id: int\n',
      );

      final parser = YamlParser(eventsPath: eventsPath);
      final domains = await parser.parseEvents();

      final loginEvent = domains['auth']!.events.first;
      expect(loginEvent.parameters.length, equals(2));
      expect(loginEvent.deprecated, isTrue);
      expect(loginEvent.replacement, equals('auth.login_v2'));

      final methodParam = loginEvent.parameters[0];
      expect(methodParam.name, equals('method'));
      expect(methodParam.type, equals('string'));
      expect(methodParam.isNullable, isFalse);

      final userIdParam = loginEvent.parameters[1];
      expect(userIdParam.name, equals('user_id'));
      expect(userIdParam.type, equals('int'));
      expect(userIdParam.isNullable, isFalse);
    });

    test('parses nullable parameters', () async {
      final yamlFile = File(path.join(eventsPath, 'auth.yaml'));
      await yamlFile.writeAsString(
          'auth:\n  signup:\n    description: User signs up\n    parameters:\n      referral_code: string?\n');

      final parser = YamlParser(eventsPath: eventsPath);
      final domains = await parser.parseEvents();

      final param = domains['auth']!.events.first.parameters.first;
      expect(param.type, equals('string'));
      expect(param.isNullable, isTrue);
    });

    test('parses allowed_values for parameters', () async {
      final yamlFile = File(path.join(eventsPath, 'auth.yaml'));
      await yamlFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: User logs in\n'
        '    parameters:\n'
        '      method:\n'
        '        type: string\n'
        '        allowed_values: [email, google, apple]\n',
      );

      final parser = YamlParser(eventsPath: eventsPath);
      final domains = await parser.parseEvents();

      final param = domains['auth']!.events.first.parameters.first;
      expect(param.allowedValues, equals(['email', 'google', 'apple']));
    });

    test('applies param_name override for analytics key', () async {
      final yamlFile = File(path.join(eventsPath, 'auth.yaml'));
      await yamlFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: User logs in\n'
        '    parameters:\n'
        '      tracking_id:\n'
        '        type: string\n'
        '        param_name: tracking-id\n',
      );

      final parser = YamlParser(eventsPath: eventsPath);
      final domains = await parser.parseEvents();

      final param = domains['auth']!.events.first.parameters.first;
      expect(param.name, equals('tracking-id'));
      expect(param.codeName, equals('tracking_id'));
    });

    test('parses meta field for events and parameters', () async {
      final yamlFile = File(path.join(eventsPath, 'auth.yaml'));
      await yamlFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: User logs in\n'
        '    meta:\n'
        '      owner: team-auth\n'
        '      is_pii: false\n'
        '    parameters:\n'
        '      email:\n'
        '        type: string\n'
        '        meta:\n'
        '          is_pii: true\n',
      );

      final parser = YamlParser(eventsPath: eventsPath);
      final domains = await parser.parseEvents();

      final event = domains['auth']!.events.first;
      expect(event.meta, equals({'owner': 'team-auth', 'is_pii': false}));

      final param = event.parameters.first;
      expect(param.meta, equals({'is_pii': true}));
    });

    test('throws when meta is not a map', () async {
      final yamlFile = File(path.join(eventsPath, 'auth.yaml'));
      await yamlFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: User logs in\n'
        '    meta: "invalid"\n'
        '    parameters: {}\n',
      );

      final parser = YamlParser(eventsPath: eventsPath);

      expect(
        () => parser.parseEvents(),
        throwsA(
          isA<AnalyticsAggregateException>().having(
            (e) => e.errors.first.message,
            'message',
            contains('The "meta" field must be a map'),
          ),
        ),
      );
    });

    test('returns empty map when events directory does not exist', () async {
      final messages = <String>[];
      final parser =
          YamlParser(eventsPath: '/nonexistent/path', log: messages.add);
      final domains = await parser.parseEvents();
      expect(domains, isEmpty);
      expect(messages, contains(contains('Events directory not found')));
    });

    test('returns empty map when no YAML files found', () async {
      final messages = <String>[];
      final parser = YamlParser(eventsPath: eventsPath, log: messages.add);
      final domains = await parser.parseEvents();
      expect(domains, isEmpty);
      expect(messages, contains(contains('No YAML files found')));
    });

    test('logs and skips files that do not contain a top-level YamlMap',
        () async {
      final yamlFile = File(path.join(eventsPath, 'not_map.yaml'));
      await yamlFile.writeAsString('- list_item\n- second_item\n');

      final messages = <String>[];
      final parser = YamlParser(eventsPath: eventsPath, log: messages.add);

      final domains = await parser.parseEvents();
      expect(domains, isEmpty);
      expect(messages, hasLength(2));
      expect(messages.any((m) => m.contains('does not contain a YamlMap')),
          isTrue);
    });

    test('throws when domain value is not a map', () async {
      final yamlFile = File(path.join(eventsPath, 'auth.yaml'));
      await yamlFile.writeAsString('auth: 123\n');

      final parser = YamlParser(eventsPath: eventsPath);

      expect(
        () => parser.parseEvents(),
        throwsA(
          isA<AnalyticsAggregateException>().having(
            (e) => e.errors.first.message,
            'message',
            contains('Domain "auth"'),
          ),
        ),
      );
    });

    test('throws when event value is not a map', () async {
      final yamlFile = File(path.join(eventsPath, 'auth.yaml'));
      await yamlFile.writeAsString('auth:\n  login: 1\n');

      final parser = YamlParser(eventsPath: eventsPath);

      expect(
        () => parser.parseEvents(),
        throwsA(
          isA<AnalyticsAggregateException>().having(
            (e) => e.errors.first.message,
            'message',
            contains('Event "auth.login"'),
          ),
        ),
      );
    });

    test('throws when parameters is not a map', () async {
      final yamlFile = File(path.join(eventsPath, 'auth.yaml'));
      await yamlFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: Test\n'
        '    parameters: 1\n',
      );

      final parser = YamlParser(eventsPath: eventsPath);

      expect(
        () => parser.parseEvents(),
        throwsA(
          isA<AnalyticsAggregateException>().having(
            (e) => e.errors.first.message,
            'message',
            contains('Parameters for event "auth.login"'),
          ),
        ),
      );
    });

    test('throws when parameter name is not snake_case', () async {
      final yamlFile = File(path.join(eventsPath, 'auth.yaml'));
      await yamlFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: Test\n'
        '    parameters:\n'
        '      Method: string\n',
      );

      final parser = YamlParser(eventsPath: eventsPath);

      expect(
        () => parser.parseEvents(),
        throwsA(
          isA<AnalyticsAggregateException>().having(
            (e) => e.errors.first.message,
            'message',
            contains('violates the configured naming strategy'),
          ),
        ),
      );
    });

    test('allows legacy parameter names when enforcement disabled', () async {
      final yamlFile = File(path.join(eventsPath, 'auth.yaml'));
      await yamlFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: Test\n'
        '    parameters:\n'
        '      User-ID:\n'
        '        type: string\n'
        '        identifier: user_id\n',
      );

      final parser = YamlParser(
        eventsPath: eventsPath,
        naming: const NamingStrategy(enforceSnakeCaseParameters: false),
      );

      final domains = await parser.parseEvents();
      final param = domains['auth']!.events.first.parameters.first;
      expect(param.name, equals('User-ID'));
      expect(param.codeName, equals('user_id'));
    });

    test('throws when parameter names conflict after camelCase', () async {
      final yamlFile = File(path.join(eventsPath, 'auth.yaml'));
      await yamlFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: Test\n'
        '    parameters:\n'
        '      user_id: string\n'
        '      user__id: string\n',
      );

      final parser = YamlParser(eventsPath: eventsPath);

      expect(
        () => parser.parseEvents(),
        throwsA(
          isA<AnalyticsAggregateException>().having(
            (e) => e.errors.first.message,
            'message',
            contains('conflicts with'),
          ),
        ),
      );
    });

    test('duplicate parameter raw names via YAML loader throws', () async {
      final yamlFile = File(path.join(eventsPath, 'auth.yaml'));
      await yamlFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: Test\n'
        '    parameters:\n'
        '      a: string\n'
        '      a: int\n',
      );

      final parser = YamlParser(eventsPath: eventsPath);

      expect(
        () => parser.parseEvents(),
        throwsA(isA<YamlException>()),
      );
    });

    test('throws when duplicate parameter raw names defined (via objects)',
        () async {
      // Create two distinct keys whose `toString()` values are equal — this
      // mirrors the string duplication check in `seenRawNames` while avoiding
      // the YAML loader's duplicate-key error.
      // keys are created using the top-level KeyWithToString helper.

      final parameters = <Object, Object>{
        KeyWithToString('a'): 'string',
        KeyWithToString('b'): 'int',
      };

      final yamlMap = YamlMap.wrap(parameters);

      expect(
        () => YamlParser.parseParametersFromYaml(
          yamlMap,
          domainName: 'auth',
          eventName: 'dup',
          filePath: 'file.yaml',
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Duplicate parameter "dup"'),
          ),
        ),
      );
    });

    test('fallback type key when explicit type is missing', () async {
      final yamlFile = File(path.join(eventsPath, 'auth.yaml'));
      await yamlFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: Test\n'
        '    parameters:\n'
        '      color:\n'
        '        string: true\n',
      );

      final parser = YamlParser(eventsPath: eventsPath);
      final domains = await parser.parseEvents();

      final param = domains['auth']!.events.first.parameters.first;
      expect(param.type, equals('string'));
    });

    test('throws when allowed_values is not a list', () async {
      final yamlFile = File(path.join(eventsPath, 'auth.yaml'));
      await yamlFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: Test\n'
        '    parameters:\n'
        '      method:\n'
        '        type: string\n'
        '        allowed_values: 1\n',
      );

      final parser = YamlParser(eventsPath: eventsPath);

      expect(
        () => parser.parseEvents(),
        throwsA(isA<AnalyticsAggregateException>().having(
            (e) => e.errors.first.message,
            'message',
            contains('allowed_values'))),
      );
    });

    test('throws when domain name is not snake_case', () async {
      final yamlFile = File(path.join(eventsPath, 'auth.yaml'));
      await yamlFile
          .writeAsString('AuthDomain:\n  login:\n    description: Test\n');

      final parser = YamlParser(eventsPath: eventsPath);

      expect(
        () => parser.parseEvents(),
        throwsA(
          isA<AnalyticsAggregateException>().having(
            (e) => e.errors.first.message,
            'message',
            contains('violates the configured naming strategy'),
          ),
        ),
      );
    });

    test('throws StateError when duplicate domain defined across files',
        () async {
      final yamlFile = File(path.join(eventsPath, 'file1.yaml'));
      await yamlFile.writeAsString('auth:\n  login:\n    description: Test\n');

      final yamlFile2 = File(path.join(eventsPath, 'file2.yaml'));
      await yamlFile2
          .writeAsString('auth:\n  logout:\n    description: Test2\n');

      final parser = YamlParser(eventsPath: eventsPath);

      expect(
        () => parser.parseEvents(),
        throwsA(isA<AnalyticsAggregateException>().having(
            (e) => e.errors.first.message,
            'message',
            contains('Duplicate domain'))),
      );
    });

    test('sorts domains and events for deterministic results', () async {
      final authFile = File(path.join(eventsPath, 'z_auth.yaml'));
      await authFile.writeAsString(
        'auth:\n'
        '  z_event:\n'
        '    description: Last\n'
        '  a_event:\n'
        '    description: First\n',
      );

      final screenFile = File(path.join(eventsPath, 'a_screen.yaml'));
      await screenFile.writeAsString(
        'screen:\n'
        '  view:\n'
        '    description: Screen view\n',
      );

      final parser = YamlParser(eventsPath: eventsPath);
      final domains = await parser.parseEvents();

      expect(domains.keys.toList(), equals(['auth', 'screen']));
      final authEvents = domains['auth']!.events.map((e) => e.name).toList();
      expect(authEvents, equals(['a_event', 'z_event']));
    });

    test('throws when custom event names duplicate across domains', () async {
      final authFile = File(path.join(eventsPath, 'auth.yaml'));
      await authFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: User logs in\n'
        '    event_name: user.login\n'
        '    parameters: {}\n',
      );

      final purchaseFile = File(path.join(eventsPath, 'purchase.yaml'));
      await purchaseFile.writeAsString(
        'purchase:\n'
        '  complete:\n'
        '    description: Purchase completed\n'
        '    event_name: user.login\n'
        '    parameters: {}\n',
      );

      final parser = YamlParser(eventsPath: eventsPath);

      expect(
        () => parser.parseEvents(),
        throwsA(
          isA<AnalyticsAggregateException>().having(
            (e) => e.errors.first.message,
            'message',
            contains('Duplicate analytics event identifier "user.login"'),
          ),
        ),
      );
    });

    test('throws when custom event matches another domain default name',
        () async {
      final authFile = File(path.join(eventsPath, 'auth.yaml'));
      await authFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: User logs in\n'
        '    parameters: {}\n',
      );

      final screenFile = File(path.join(eventsPath, 'screen.yaml'));
      await screenFile.writeAsString(
        'screen:\n'
        '  view:\n'
        '    description: Screen view\n'
        '    event_name: "auth: login"\n'
        '    parameters: {}\n',
      );

      final parser = YamlParser(eventsPath: eventsPath);

      expect(
        () => parser.parseEvents(),
        throwsA(
          isA<AnalyticsAggregateException>().having(
            (e) => e.errors.first.message,
            'message',
            contains('Duplicate analytics event identifier "auth: login"'),
          ),
        ),
      );
    });

    test('allows duplicate event names when identifiers differ', () async {
      final authFile = File(path.join(eventsPath, 'auth.yaml'));
      await authFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: User logs in\n'
        '    event_name: user.login\n'
        '    identifier: auth.login\n'
        '    parameters: {}\n',
      );

      final purchaseFile = File(path.join(eventsPath, 'purchase.yaml'));
      await purchaseFile.writeAsString(
        'purchase:\n'
        '  complete:\n'
        '    description: Purchase completed\n'
        '    event_name: user.login\n'
        '    identifier: purchase.complete\n'
        '    parameters: {}\n',
      );

      final parser = YamlParser(eventsPath: eventsPath);
      final domains = await parser.parseEvents();

      expect(domains.length, equals(2));
    });
  });
}
