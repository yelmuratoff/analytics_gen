import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:analytics_gen/src/util/event_naming.dart';
import 'package:test/test.dart';

void main() {
  group('EventNaming', () {
    test('resolveEventName uses custom event when provided', () {
      final event = AnalyticsEvent(
        name: 'login',
        description: 'User signs in',
        customEventName: 'auth: login_custom',
        parameters: const [],
      );

      expect(
        EventNaming.resolveEventName('auth', event),
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
        EventNaming.resolveEventName('auth', event),
        equals('auth: logout'),
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
