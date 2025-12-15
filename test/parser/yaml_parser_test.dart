import 'dart:io';

import 'package:analytics_gen/src/config/naming_strategy.dart';
import 'package:analytics_gen/src/config/parser_config.dart';
import 'package:analytics_gen/src/core/exceptions.dart';
import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/parser/event_loader.dart';
import 'package:analytics_gen/src/parser/yaml_parser.dart';
import 'package:analytics_gen/src/util/logger.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../test_utils.dart';

// Helper type used in tests to create map keys that stringify to the same
// value while remaining distinct map keys (Dart object identity).
class KeyWithToString {
  KeyWithToString(this.id);
  final String id;

  @override
  String toString() => 'dup';
}

// A helper key used to simulate throwing exceptions from toString().
class ThrowingKey {
  @override
  String toString() =>
      throw AnalyticsParseException('boom', filePath: 'file.yaml');
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

    // (Removed duplicate ThrowingKey definition)

    Future<Map<String, AnalyticsDomain>> parseEventsHelper({
      String? customPath,
      NamingStrategy? naming,
      Logger? log,
    }) async {
      final p = customPath ?? eventsPath;
      final logger = log ?? const NoOpLogger();
      final loader = EventLoader(eventsPath: p, log: logger);
      final sources = await loader.loadEventFiles();
      final parser = YamlParser(
        config: ParserConfig(naming: naming ?? const NamingStrategy()),
        log: logger,
      );
      return parser.parseEvents(sources);
    }

    test('parses simple event without parameters', () async {
      final yamlFile = File(path.join(eventsPath, 'auth.yaml'));
      await yamlFile.writeAsString(
          'auth:\n  logout:\n    description: User logs out\n    parameters: {}\n');

      final domains = await parseEventsHelper();

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

      final domains = await parseEventsHelper();

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

      final domains = await parseEventsHelper();

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

      final domains = await parseEventsHelper();

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

      final domains = await parseEventsHelper();

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

      final domains = await parseEventsHelper();

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

      expect(
        () => parseEventsHelper(),
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
      final domains = await parseEventsHelper(
        customPath: '/nonexistent/path',
        log: TestLogger(messages),
      );
      expect(domains, isEmpty);
      expect(messages, contains(contains('Events directory not found')));
    });

    test('returns empty map when no YAML files found', () async {
      final messages = <String>[];
      final domains = await parseEventsHelper(log: TestLogger(messages));
      expect(domains, isEmpty);
      expect(messages, contains(contains('No YAML files found')));
    });

    test('throws when file does not contain a top-level YamlMap', () async {
      final yamlFile = File(path.join(eventsPath, 'not_map.yaml'));
      await yamlFile.writeAsString('- list_item\n- second_item\n');

      expect(
        () => parseEventsHelper(),
        throwsA(
          isA<AnalyticsAggregateException>().having(
            (e) => e.errors.first.message,
            'message',
            contains('Root of the YAML file must be a map'),
          ),
        ),
      );
    });

    test('throws when domain value is not a map', () async {
      final yamlFile = File(path.join(eventsPath, 'auth.yaml'));
      await yamlFile.writeAsString('auth: 123\n');

      expect(
        () => parseEventsHelper(),
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

      expect(
        () => parseEventsHelper(),
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

      expect(
        () => parseEventsHelper(),
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

      expect(
        () => parseEventsHelper(),
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

      final domains = await parseEventsHelper(
        naming: const NamingStrategy(enforceSnakeCaseParameters: false),
      );

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

      expect(
        () => parseEventsHelper(),
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

      expect(
        () => parseEventsHelper(),
        throwsA(
          isA<AnalyticsAggregateException>().having(
            (e) => e.errors.first,
            'error',
            isA<AnalyticsParseException>().having(
              (e) => e.message,
              'message',
              contains('Duplicate mapping key'),
            ),
          ),
        ),
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
        () => YamlParser().parseParameters(
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

      final domains = await parseEventsHelper();

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

      expect(
        () => parseEventsHelper(),
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

      expect(
        () => parseEventsHelper(),
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

      expect(
        () => parseEventsHelper(),
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

      final domains = await parseEventsHelper();

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

      expect(
        () => parseEventsHelper(),
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

      expect(
        () => parseEventsHelper(),
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

      final domains = await parseEventsHelper();

      expect(domains.length, equals(2));
    });

    test('throws on YAML parsing error in context files', () async {
      final contextFile = File(path.join(eventsPath, 'context.yaml'));
      await contextFile.writeAsString('invalid: yaml: content: [\n');

      final loader =
          EventLoader(eventsPath: eventsPath, contextFiles: [contextFile.path]);
      final sources = await loader.loadContextFiles();
      final parser = YamlParser();

      expect(
        () => parser.parseContexts(sources),
        throwsA(isA<AnalyticsParseException>().having(
          (e) => e.message,
          'message',
          contains('Failed to parse YAML file'),
        )),
      );
    });

    test('wraps YAML parse error for event files into AnalyticsParseException',
        () async {
      final yamlFile = File(path.join(eventsPath, 'auth.yaml'));
      // invalid YAML content causing loadYamlNode to throw
      await yamlFile.writeAsString('invalid: yaml: content: [\n');

      expect(
        () => parseEventsHelper(),
        throwsA(isA<AnalyticsAggregateException>().having(
          (e) => e.errors.first.message,
          'message',
          contains('Failed to parse YAML file'),
        )),
      );
    });

    test('wraps non-Analytics exception during event parsing', () async {
      final yamlFile = File(path.join(eventsPath, 'auth.yaml'));
      // Make description a list so the cast to String? throws a TypeError
      await yamlFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description:\n'
        '      - not_a_string\n'
        '    parameters: {}\n',
      );

      expect(
        () => parseEventsHelper(),
        throwsA(isA<AnalyticsAggregateException>().having(
          (e) => e.errors.first.innerError,
          'innerError',
          isNotNull,
        )),
      );
    });

    test('throws when context file is not a map', () async {
      final contextFile = File(path.join(eventsPath, 'context.yaml'));
      await contextFile.writeAsString('- list_item\n- second_item\n');

      final loader =
          EventLoader(eventsPath: eventsPath, contextFiles: [contextFile.path]);
      final sources = await loader.loadContextFiles();
      final parser = YamlParser();

      expect(
        () => parser.parseContexts(sources),
        throwsA(isA<AnalyticsParseException>().having(
          (e) => e.message,
          'message',
          contains('Context file must be a map'),
        )),
      );
    });

    test('throws when context properties node is null', () async {
      final contextFile = File(path.join(eventsPath, 'context.yaml'));
      await contextFile.writeAsString('context_name:\n');

      final loader =
          EventLoader(eventsPath: eventsPath, contextFiles: [contextFile.path]);
      final sources = await loader.loadContextFiles();
      final parser = YamlParser();

      expect(
        () => parser.parseContexts(sources),
        throwsA(isA<AnalyticsParseException>().having(
          (e) => e.message,
          'message',
          contains('key must be a map of properties'),
        )),
      );
    });

    test('wraps non-Analytics exception during domain parsing', () async {
      final yamlFile = File(path.join(eventsPath, 'auth.yaml'));
      await yamlFile.writeAsString('auth:\n  login:\n    description: Test\n');

      final messages = <String>[];
      final loader =
          EventLoader(eventsPath: eventsPath, log: TestLogger(messages));
      final sources = await loader.loadEventFiles();

      // Fake validator that throws a non-Analytics exception during domain validation
      final parser = YamlParser(
        log: const NoOpLogger(),
        domainHook: (domainKey, valueNode) {
          throw FormatException('boom');
        },
      );

      expect(
        () => parser.parseEvents(sources),
        throwsA(isA<AnalyticsAggregateException>().having(
          (e) => e.errors.first.innerError,
          'innerError',
          isA<FormatException>(),
        )),
      );
    });

    test(
        'calls onError when _parseEventsForDomain throws AnalyticsParseException',
        () async {
      // Craft a YamlMap where the event key's toString throws an AnalyticsParseException
      final throwingKey = ThrowingKey();
      final eventsMap = YamlMap.wrap({throwingKey: YamlMap.wrap({})});

      // Provide a loader that returns a root map with a single domain 'auth'
      final rootMap = YamlMap.wrap({'auth': eventsMap});
      YamlMap loader(String content,
              {dynamic sourceUrl, dynamic recover, dynamic errorListener}) =>
          rootMap;

      final parser = YamlParser(log: const NoOpLogger(), loadYaml: loader);
      final sources = [
        AnalyticsSource(filePath: 'file.yaml', content: 'unused')
      ];

      expect(
        () => parser.parseEvents(sources),
        throwsA(isA<AnalyticsAggregateException>().having(
          (e) => e.errors.first.message,
          'message',
          contains('boom'),
        )),
      );
    });

    // Note: The branch checking for a missing properties node is exercised by
    // the existing test above which writes `context_name:\n` and triggers a
    // YamlScalar null value; we consider that coverage for the missing-node
    // and explicit null value cases combined.
  });
}
