import 'package:analytics_gen/analytics_gen.dart';
import 'package:test/test.dart';

void main() {
  group('RecordedAnalyticsEvent', () {
    test('supports value equality and hashCode', () {
      final timestamp = DateTime.parse('2025-01-01T12:00:00Z');
      final eventA = RecordedAnalyticsEvent(
        name: 'auth: login',
        parameters: {'method': 'email'},
        timestamp: timestamp,
      );
      final eventB = RecordedAnalyticsEvent(
        name: 'auth: login',
        parameters: {'method': 'email'},
        timestamp: timestamp,
      );
      final eventC = RecordedAnalyticsEvent(
        name: 'auth: login',
        parameters: {'method': 'email'},
        timestamp: timestamp.add(const Duration(seconds: 1)),
      );

      expect(eventA, equals(eventB));
      expect(eventA.hashCode, equals(eventB.hashCode));
      expect(eventA, isNot(equals(eventC)));
    });

    test('toMap produces legacy-compatible shape', () {
      final timestamp = DateTime.parse('2025-01-01T12:00:00Z');
      final event = RecordedAnalyticsEvent(
        name: 'auth: logout',
        parameters: {'method': 'app'},
        timestamp: timestamp,
      );

      final map = event.toMap();
      expect(map['name'], equals('auth: logout'));
      expect(map['parameters'], equals(event.parameters));
      expect(map['timestamp'], equals(timestamp.toIso8601String()));
    });
  });
}
