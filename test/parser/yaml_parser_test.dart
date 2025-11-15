import 'dart:io';

import 'package:analytics_gen/src/parser/yaml_parser.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

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

    test('returns empty map when events directory does not exist', () async {
      final parser = YamlParser(eventsPath: '/nonexistent/path');
      final domains = await parser.parseEvents();
      expect(domains, isEmpty);
    });

    test('returns empty map when no YAML files found', () async {
      final parser = YamlParser(eventsPath: eventsPath);
      final domains = await parser.parseEvents();
      expect(domains, isEmpty);
    });

    test('throws when domain value is not a map', () async {
      final yamlFile = File(path.join(eventsPath, 'auth.yaml'));
      await yamlFile.writeAsString('auth: 123\n');

      final parser = YamlParser(eventsPath: eventsPath);

      expect(
        () => parser.parseEvents(),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
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
          isA<FormatException>().having(
            (e) => e.message,
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
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Parameters for event "auth.login"'),
          ),
        ),
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
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('must use snake_case'),
          ),
        ),
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
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Duplicate analytics event name "user.login"'),
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
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Duplicate analytics event name "auth: login"'),
          ),
        ),
      );
    });
  });
}
