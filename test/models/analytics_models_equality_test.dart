import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:test/test.dart';

void main() {
  group('Analytics models equality', () {
    test('AnalyticsParameter supports value equality', () {
      const a = AnalyticsParameter(
        name: 'method',
        type: 'string',
        isNullable: false,
      );
      const b = AnalyticsParameter(
        name: 'method',
        type: 'string',
        isNullable: false,
      );
      const c = AnalyticsParameter(
        name: 'other',
        type: 'string',
        isNullable: false,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('AnalyticsEvent compares parameters deeply', () {
      const params = [
        AnalyticsParameter(
          name: 'method',
          type: 'string',
          isNullable: false,
        ),
      ];

      const event1 = AnalyticsEvent(
        name: 'login',
        description: 'User logs in',
        parameters: params,
      );
      const event2 = AnalyticsEvent(
        name: 'login',
        description: 'User logs in',
        parameters: params,
      );

      expect(event1, equals(event2));
      expect(event1.hashCode, equals(event2.hashCode));

      const event3 = AnalyticsEvent(
        name: 'login',
        description: 'Different',
        parameters: params,
      );

      expect(event1, isNot(equals(event3)));
    });

    test('AnalyticsDomain compares events deeply and works in sets', () {
      const event = AnalyticsEvent(
        name: 'login',
        description: 'User logs in',
        parameters: [
          AnalyticsParameter(
            name: 'method',
            type: 'string',
            isNullable: false,
          ),
        ],
      );

      const domain1 = AnalyticsDomain(
        name: 'auth',
        events: [event],
      );
      const domain2 = AnalyticsDomain(
        name: 'auth',
        events: [event],
      );

      expect(domain1, equals(domain2));
      expect(domain1.hashCode, equals(domain2.hashCode));

      final set = {domain1};
      expect(set.contains(domain2), isTrue);
    });
  });
}

