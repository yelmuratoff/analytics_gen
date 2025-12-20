import 'package:analytics_gen/src/config/naming_strategy.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:analytics_gen/src/util/event_naming.dart';
import 'package:test/test.dart';

void main() {
  group('EventNaming', () {
    const naming = NamingStrategy();

    test('resolveEventName uses custom event when provided', () {
      final event = AnalyticsEvent(
        name: 'login',
        description: 'User signs in',
        customEventName: 'auth: login_custom',
        parameters: const [],
      );

      expect(
        EventNaming.resolveEventName('auth', event, naming),
        equals('auth: login_custom'),
      );
    });

    test('resolveEventName falls back to domain:event when no custom name', () {
      final event = AnalyticsEvent(
        name: 'logout',
        description: 'User logs out',
        parameters: const [],
      );

      expect(
        EventNaming.resolveEventName('auth', event, naming),
        equals('auth_logout'),
      );
    });

    test('resolveIdentifier prefers explicit identifier', () {
      final event = AnalyticsEvent(
        name: 'logout',
        description: 'User logs out',
        identifier: 'legacy.logout',
        parameters: const [],
      );

      expect(
        EventNaming.resolveIdentifier('auth', event, naming),
        equals('legacy.logout'),
      );
    });

    test('resolveIdentifier falls back to template', () {
      final customNaming =
          NamingStrategy(identifierTemplate: '{domain}.{event}');
      final event = AnalyticsEvent(
        name: 'login',
        description: 'User logs in',
        parameters: const [],
      );

      expect(
        EventNaming.resolveIdentifier('auth', event, customNaming),
        equals('auth.login'),
      );
    });

    test('resolveIdentifier reuses custom event name when identifier missing',
        () {
      final event = AnalyticsEvent(
        name: 'login',
        description: 'User logs in',
        customEventName: 'legacy_login',
        parameters: const [],
      );

      expect(
        EventNaming.resolveIdentifier('auth', event, const NamingStrategy()),
        equals('legacy_login'),
      );
    });

    test('buildLoggerMethodName composes camelCased name from snake_case', () {
      expect(
        EventNaming.buildLoggerMethodName('auth', 'user_login'),
        equals('logAuthUserLogin'),
      );
    });

    test('buildLoggerMethodName includes multi_segment events', () {
      expect(
        EventNaming.buildLoggerMethodName('analytics', 'purchase_item_created'),
        equals('logAnalyticsPurchaseItemCreated'),
      );
    });
  });
}
