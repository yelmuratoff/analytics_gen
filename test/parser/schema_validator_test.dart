import 'package:analytics_gen/src/config/naming_strategy.dart';
import 'package:analytics_gen/src/core/exceptions.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:analytics_gen/src/parser/schema_validator.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('SchemaValidator', () {
    late SchemaValidator validator;
    late NamingStrategy naming;

    setUp(() {
      naming = const NamingStrategy();
      validator = SchemaValidator(naming);
    });

    group('validateDomainName', () {
      test('accepts valid snake_case domain names', () {
        expect(() => validator.validateDomainName('auth', 'test.yaml'),
            returnsNormally);
        expect(() => validator.validateDomainName('user_profile', 'test.yaml'),
            returnsNormally);
      });

      test('throws for invalid domain names', () {
        expect(
          () => validator.validateDomainName('Auth', 'test.yaml'),
          throwsA(isA<AnalyticsParseException>()),
        );
        expect(
          () => validator.validateDomainName('userProfile', 'test.yaml'),
          throwsA(isA<AnalyticsParseException>()),
        );
        expect(
          () => validator.validateDomainName('user-profile', 'test.yaml'),
          throwsA(isA<AnalyticsParseException>()),
        );
      });
    });

    group('validateUniqueEventNames', () {
      test('accepts unique event names across domains', () {
        final domains = {
          'auth': AnalyticsDomain(
            name: 'auth',
            events: [
              AnalyticsEvent(
                name: 'login',
                description: 'User logged in',
                parameters: [],
                meta: {},
              ),
            ],
          ),
          'profile': AnalyticsDomain(
            name: 'profile',
            events: [
              AnalyticsEvent(
                name: 'update',
                description: 'User updated profile',
                parameters: [],
                meta: {},
              ),
            ],
          ),
        };

        expect(
            () => validator.validateUniqueEventNames(domains), returnsNormally);
      });

      test('detects duplicate event identifiers across domains', () {
        final domainsWithConflict = {
          'auth': AnalyticsDomain(
            name: 'auth',
            events: [
              AnalyticsEvent(
                name: 'login',
                identifier: 'user_login_action',
                description: 'User logged in',
                parameters: [],
                meta: {},
              ),
            ],
          ),
          'user': AnalyticsDomain(
            name: 'user',
            events: [
              AnalyticsEvent(
                name: 'signin',
                identifier: 'user_login_action', // CONFLICT
                description: 'User signed in',
                parameters: [],
                meta: {},
              ),
            ],
          ),
        };

        var errorCount = 0;
        validator.validateUniqueEventNames(
          domainsWithConflict,
          onError: (e) {
            errorCount++;
            expect(e.message, contains('Duplicate analytics event identifier'));
          },
        );
        expect(errorCount, 1);
      });
    });

    group('validateRootMap', () {
      test('accepts valid map', () {
        final node = loadYamlNode('domain: {}');
        expect(() => validator.validateRootMap(node, 'test.yaml'),
            returnsNormally);
      });

      test('throws for non-map', () {
        final node = loadYamlNode('[]', sourceUrl: Uri.parse('test.yaml'));
        expect(
          () => validator.validateRootMap(node, 'test.yaml'),
          throwsA(isA<AnalyticsParseException>()),
        );
      });

      test('ignores empty file (null scalar)', () {
        final node = loadYamlNode('');
        expect(() => validator.validateRootMap(node, 'test.yaml'),
            returnsNormally);
      });
    });

    group('validateDomainMap', () {
      test('accepts valid map', () {
        final node = loadYamlNode('event: {}');
        expect(() => validator.validateDomainMap(node, 'domain', 'test.yaml'),
            returnsNormally);
      });

      test('throws for non-map', () {
        final node = loadYamlNode('string', sourceUrl: Uri.parse('test.yaml'));
        expect(
          () => validator.validateDomainMap(node, 'domain', 'test.yaml'),
          throwsA(isA<AnalyticsParseException>()),
        );
      });
    });

    group('validateEventMap', () {
      test('accepts valid map', () {
        final node = loadYamlNode('description: test');
        expect(
            () => validator.validateEventMap(
                node, 'domain', 'event', 'test.yaml'),
            returnsNormally);
      });

      test('throws for non-map', () {
        final node = loadYamlNode('string', sourceUrl: Uri.parse('test.yaml'));
        expect(
          () => validator.validateEventMap(
              node, 'domain', 'event', 'test.yaml'),
          throwsA(isA<AnalyticsParseException>()),
        );
      });
    });

    group('validateParametersMap', () {
      test('accepts valid map', () {
        final node = loadYamlNode('param: { type: string }');
        expect(
            () => validator.validateParametersMap(
                node, 'domain', 'event', 'test.yaml'),
            returnsNormally);
      });

      test('throws for non-map', () {
        final node = loadYamlNode('[]', sourceUrl: Uri.parse('test.yaml'));
        expect(
          () => validator.validateParametersMap(
              node, 'domain', 'event', 'test.yaml'),
          throwsA(isA<AnalyticsParseException>()),
        );
      });
    });

    group('validateMetaMap', () {
      test('accepts valid map', () {
        final node = loadYamlNode('key: value');
        expect(() => validator.validateMetaMap(node, 'test.yaml'),
            returnsNormally);
      });

      test('throws for non-map', () {
        final node = loadYamlNode('string', sourceUrl: Uri.parse('test.yaml'));
        expect(
          () => validator.validateMetaMap(node, 'test.yaml'),
          throwsA(isA<AnalyticsParseException>()),
        );
      });
    });

    group('validateContextRoot', () {
      test('accepts valid map with single key', () {
        final node = loadYamlNode('context: {}');
        expect(() => validator.validateContextRoot(node, 'test.yaml'),
            returnsNormally);
      });

      test('throws for non-map', () {
        final node = loadYamlNode('[]', sourceUrl: Uri.parse('test.yaml'));
        expect(
          () => validator.validateContextRoot(node, 'test.yaml'),
          throwsA(isA<AnalyticsParseException>()),
        );
      });

      test('throws for map with multiple keys', () {
        final node = loadYamlNode('context1: {}\ncontext2: {}',
            sourceUrl: Uri.parse('test.yaml'));
        expect(
          () => validator.validateContextRoot(node, 'test.yaml'),
          throwsA(isA<AnalyticsParseException>()),
        );
      });
    });

    group('validateContextProperties', () {
      test('accepts valid map', () {
        final node = loadYamlNode('prop: { type: string }');
        expect(
            () => validator.validateContextProperties(
                node, 'context', 'test.yaml'),
            returnsNormally);
      });

      test('throws for non-map', () {
        final node = loadYamlNode('string', sourceUrl: Uri.parse('test.yaml'));
        expect(
          () => validator.validateContextProperties(
              node, 'context', 'test.yaml'),
          throwsA(isA<AnalyticsParseException>()),
        );
      });
    });
  });
}
