import 'package:analytics_gen/src/config/naming_strategy.dart';
import 'package:analytics_gen/src/config/parser_config.dart';
import 'package:analytics_gen/src/core/exceptions.dart';
import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/parser/event_loader.dart';
import 'package:analytics_gen/src/parser/yaml_parser.dart';
import 'package:analytics_gen/src/util/logger.dart';
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
    // Helper to run the parser with in-memory content
    Future<Map<String, AnalyticsDomain>> parseEventsHelper({
      required Map<String, String> files,
      NamingStrategy? naming,
      Logger? log,
      String? customPath,
    }) async {
      // Mock loading by creating sources directly from the map
      final sources = files.entries.map((e) {
        return AnalyticsSource(
          filePath: e.key,
          content: e.value,
        );
      }).toList();

      final parser = YamlParser(
        config: ParserConfig(naming: naming ?? const NamingStrategy()),
        log: log ?? const NoOpLogger(),
      );
      return parser.parseEvents(sources);
    }

    test('parses simple event without parameters', () async {
      final files = {
        'auth.yaml':
            'auth:\n  logout:\n    description: User logs out\n    parameters: {}\n'
      };

      final domains = await parseEventsHelper(files: files);

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
      final files = {
        'auth.yaml': 'auth:\n'
            '  login:\n'
            '    description: User logs in\n'
            '    deprecated: true\n'
            '    replacement: auth.login_v2\n'
            '    parameters:\n'
            '      method: string\n'
            '      user_id: int\n'
      };

      final domains = await parseEventsHelper(files: files);

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
      final files = {
        'auth.yaml':
            'auth:\n  signup:\n    description: User signs up\n    parameters:\n      referral_code: string?\n'
      };

      final domains = await parseEventsHelper(files: files);

      final param = domains['auth']!.events.first.parameters.first;
      expect(param.type, equals('string'));
      expect(param.isNullable, isTrue);
    });

    test('parses allowed_values for parameters', () async {
      final files = {
        'auth.yaml': 'auth:\n'
            '  login:\n'
            '    description: User logs in\n'
            '    parameters:\n'
            '      method:\n'
            '        type: string\n'
            '        allowed_values: [email, google, apple]\n'
      };

      final domains = await parseEventsHelper(files: files);

      final param = domains['auth']!.events.first.parameters.first;
      expect(param.allowedValues, equals(['email', 'google', 'apple']));
    });

    test('applies param_name override for analytics key', () async {
      final files = {
        'auth.yaml': 'auth:\n'
            '  login:\n'
            '    description: User logs in\n'
            '    parameters:\n'
            '      tracking_id:\n'
            '        type: string\n'
            '        param_name: tracking-id\n'
      };

      final domains = await parseEventsHelper(files: files);

      final param = domains['auth']!.events.first.parameters.first;
      expect(param.name, equals('tracking-id'));
      expect(param.codeName, equals('tracking_id'));
    });

    test('parses meta field for events and parameters', () async {
      final files = {
        'auth.yaml': 'auth:\n'
            '  login:\n'
            '    description: User logs in\n'
            '    meta:\n'
            '      owner: team-auth\n'
            '      is_pii: false\n'
            '    parameters:\n'
            '      email:\n'
            '        type: string\n'
            '        meta:\n'
            '          is_pii: true\n'
      };

      final domains = await parseEventsHelper(files: files);

      final event = domains['auth']!.events.first;
      expect(event.meta, equals({'owner': 'team-auth', 'is_pii': false}));

      final param = event.parameters.first;
      expect(param.meta, equals({'is_pii': true}));
    });

    test('throws when meta is not a map', () async {
      final files = {
        'auth.yaml': 'auth:\n'
            '  login:\n'
            '    description: User logs in\n'
            '    meta: "invalid"\n'
            '    parameters: {}\n'
      };

      expect(
        () => parseEventsHelper(files: files),
        throwsA(
          isA<AnalyticsAggregateException>().having(
            (e) => e.errors.first.message,
            'message',
            contains('The "meta" field must be a map'),
          ),
        ),
      );
    });

    test('returns empty map when no YAML files found', () async {
      final messages = <String>[];
      final domains = await parseEventsHelper(
        files: {},
        log: TestLogger(messages),
      );
      expect(domains, isEmpty);
    });

    test('throws when file does not contain a top-level YamlMap', () async {
      final files = {'not_map.yaml': '- list_item\n- second_item\n'};

      expect(
        () => parseEventsHelper(files: files),
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
      final files = {'auth.yaml': 'auth: 123\n'};

      expect(
        () => parseEventsHelper(files: files),
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
      final files = {'auth.yaml': 'auth:\n  login: 1\n'};

      expect(
        () => parseEventsHelper(files: files),
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
      final files = {
        'auth.yaml': 'auth:\n'
            '  login:\n'
            '    description: Test\n'
            '    parameters: 1\n'
      };

      expect(
        () => parseEventsHelper(files: files),
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
      final files = {
        'auth.yaml': 'auth:\n'
            '  login:\n'
            '    description: Test\n'
            '    parameters:\n'
            '      Method: string\n'
      };

      expect(
        () => parseEventsHelper(files: files),
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
      final files = {
        'auth.yaml': 'auth:\n'
            '  login:\n'
            '    description: Test\n'
            '    parameters:\n'
            '      User-ID:\n'
            '        type: string\n'
            '        identifier: user_id\n'
      };

      final domains = await parseEventsHelper(
        files: files,
        naming: const NamingStrategy(enforceSnakeCaseParameters: false),
      );

      final param = domains['auth']!.events.first.parameters.first;
      expect(param.name, equals('User-ID'));
      expect(param.codeName, equals('user_id'));
    });

    test('throws when parameter names conflict after camelCase', () async {
      final files = {
        'auth.yaml': 'auth:\n'
            '  login:\n'
            '    description: Test\n'
            '    parameters:\n'
            '      user_id: string\n'
            '      user__id: string\n'
      };

      expect(
        () => parseEventsHelper(files: files),
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
      final files = {
        'auth.yaml': 'auth:\n'
            '  login:\n'
            '    description: Test\n'
            '    parameters:\n'
            '      a: string\n'
            '      a: int\n'
      };

      expect(
        () => parseEventsHelper(files: files),
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
      final files = {
        'auth.yaml': 'auth:\n'
            '  login:\n'
            '    description: Test\n'
            '    parameters:\n'
            '      color:\n'
            '        string: true\n'
      };

      final domains = await parseEventsHelper(files: files);

      final param = domains['auth']!.events.first.parameters.first;
      expect(param.type, equals('string'));
    });

    test('throws when allowed_values is not a list', () async {
      final files = {
        'auth.yaml': 'auth:\n'
            '  login:\n'
            '    description: Test\n'
            '    parameters:\n'
            '      method:\n'
            '        type: string\n'
            '        allowed_values: 1\n'
      };

      expect(
        () => parseEventsHelper(files: files),
        throwsA(isA<AnalyticsAggregateException>().having(
            (e) => e.errors.first.message,
            'message',
            contains('allowed_values'))),
      );
    });

    test('throws when domain name is not snake_case', () async {
      final files = {
        'auth.yaml': 'AuthDomain:\n  login:\n    description: Test\n'
      };

      expect(
        () => parseEventsHelper(files: files),
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
      final files = {
        'file1.yaml': 'auth:\n  login:\n    description: Test\n',
        'file2.yaml': 'auth:\n  logout:\n    description: Test2\n'
      };

      expect(
        () => parseEventsHelper(files: files),
        throwsA(isA<AnalyticsAggregateException>().having(
            (e) => e.errors.first.message,
            'message',
            contains('Duplicate domain'))),
      );
    });

    test('sorts domains and events for deterministic results', () async {
      final files = {
        'z_auth.yaml': 'auth:\n'
            '  z_event:\n'
            '    description: Last\n'
            '  a_event:\n'
            '    description: First\n',
        'a_screen.yaml': 'screen:\n'
            '  view:\n'
            '    description: Screen view\n'
      };

      final domains = await parseEventsHelper(files: files);

      expect(domains.keys.toList(), equals(['auth', 'screen']));
      final authEvents = domains['auth']!.events.map((e) => e.name).toList();
      expect(authEvents, equals(['a_event', 'z_event']));
    });

    test('throws when custom event names duplicate across domains', () async {
      final files = {
        'auth.yaml': 'auth:\n'
            '  login:\n'
            '    description: User logs in\n'
            '    event_name: user.login\n'
            '    parameters: {}\n',
        'purchase.yaml': 'purchase:\n'
            '  complete:\n'
            '    description: Purchase completed\n'
            '    event_name: user.login\n'
            '    parameters: {}\n'
      };

      expect(
        () => parseEventsHelper(files: files),
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
      final files = {
        'auth.yaml': 'auth:\n'
            '  login:\n'
            '    description: User logs in\n'
            '    parameters: {}\n',
        'screen.yaml': 'screen:\n'
            '  view:\n'
            '    description: Screen view\n'
            '    event_name: "auth: login"\n'
            '    parameters: {}\n'
      };

      expect(
        () => parseEventsHelper(files: files),
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
      final files = {
        'auth.yaml': 'auth:\n'
            '  login:\n'
            '    description: User logs in\n'
            '    event_name: user.login\n'
            '    identifier: auth.login\n'
            '    parameters: {}\n',
        'purchase.yaml': 'purchase:\n'
            '  complete:\n'
            '    description: Purchase completed\n'
            '    event_name: user.login\n'
            '    identifier: purchase.complete\n'
            '    parameters: {}\n'
      };

      final domains = await parseEventsHelper(files: files);

      expect(domains.length, equals(2));
    });

    test('throws upon parsing error in context files (simulated)', () async {
      final sources = [
        AnalyticsSource(
          filePath: 'context.yaml',
          content: 'invalid: yaml: content: [\n',
        )
      ];

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
      final files = {'auth.yaml': 'invalid: yaml: content: [\n'};

      expect(
        () => parseEventsHelper(files: files),
        throwsA(isA<AnalyticsAggregateException>().having(
          (e) => e.errors.first.message,
          'message',
          contains('Failed to parse YAML file'),
        )),
      );
    });

    test('wraps non-Analytics exception during event parsing', () async {
      final files = {
        'auth.yaml': 'auth:\n'
            '  login:\n'
            '    description:\n'
            '      - not_a_string\n'
            '    parameters: {}\n'
      };

      expect(
        () => parseEventsHelper(files: files),
        throwsA(isA<AnalyticsAggregateException>().having(
          (e) => e.errors.first.innerError,
          'innerError',
          isNotNull,
        )),
      );
    });

    test('throws when context file is not a map', () async {
      final sources = [
        AnalyticsSource(
          filePath: 'context.yaml',
          content: '- list_item\n- second_item\n',
        )
      ];

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
      final sources = [
        AnalyticsSource(
          filePath: 'context.yaml',
          content: 'context_name:\n',
        )
      ];

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
      final sources = [
        AnalyticsSource(
          filePath: 'auth.yaml',
          content: 'auth:\n  login:\n    description: Test\n',
        )
      ];

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
      final throwingKey = ThrowingKey();
      final eventsMap = YamlMap.wrap({throwingKey: YamlMap.wrap({})});
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
  });
}
