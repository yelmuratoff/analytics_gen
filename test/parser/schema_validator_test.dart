import 'package:analytics_gen/src/config/naming_strategy.dart';
import 'package:analytics_gen/src/core/exceptions.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:analytics_gen/src/parser/schema_validator.dart';
import 'package:test/test.dart';

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
  });
}
