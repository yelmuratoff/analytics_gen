import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';
import 'package:test/test.dart';

void main() {
  group('Analytics models toString and equality extras', () {
    test('AnalyticsParameter toString includes ? when nullable', () {
      const nullableParam = AnalyticsParameter(
        name: 'price',
        type: 'double',
        isNullable: true,
      );

      const nonNullableParam = AnalyticsParameter(
        name: 'method',
        type: 'string',
        isNullable: false,
      );

      expect(nullableParam.toString(), equals('price: double?'));
      expect(nonNullableParam.toString(), equals('method: string'));
    });

    test('AnalyticsParameter equality considers allowedValues list', () {
      const a = AnalyticsParameter(
        name: 'currency',
        type: 'string',
        isNullable: false,
        allowedValues: ['USD', 'EUR'],
      );
      const b = AnalyticsParameter(
        name: 'currency',
        type: 'string',
        isNullable: false,
        allowedValues: ['USD', 'EUR'],
      );

      const c = AnalyticsParameter(
        name: 'currency',
        type: 'string',
        isNullable: false,
        allowedValues: ['GBP'],
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('AnalyticsEvent toString shows parameter count', () {
      const params = [
        AnalyticsParameter(name: 'method', type: 'string', isNullable: false),
      ];

      const event = AnalyticsEvent(
        name: 'login',
        description: 'User logs in',
        parameters: params,
      );

      expect(event.toString(), equals('login (1 parameters)'));
    });

    test('AnalyticsEvent equality includes custom event name and flags', () {
      const params = [
        AnalyticsParameter(name: 'method', type: 'string', isNullable: false),
      ];

      const base = AnalyticsEvent(
        name: 'logout',
        description: 'User logs out',
        parameters: params,
      );

      const withCustom = AnalyticsEvent(
        name: 'logout',
        description: 'User logs out',
        customEventName: 'user_logout',
        parameters: params,
      );

      const deprecatedEvent = AnalyticsEvent(
        name: 'logout',
        description: 'User logs out',
        parameters: params,
        deprecated: true,
      );

      expect(base, isNot(equals(withCustom)));
      expect(base, isNot(equals(deprecatedEvent)));
      expect(withCustom, isNot(equals(deprecatedEvent)));
      // differing replacement differs
      const withReplacement = AnalyticsEvent(
        name: 'logout',
        description: 'User logs out',
        parameters: params,
        replacement: 'auth.logout_v2',
      );

      expect(base, isNot(equals(withReplacement)));
      expect(withCustom, isNot(equals(withReplacement)));
    });

    test(
        'AnalyticsEvent deep-compare parameters when lists are different objects',
        () {
      const paramsA = [
        AnalyticsParameter(name: 'method', type: 'string', isNullable: false),
      ];
      const paramsB = [
        AnalyticsParameter(name: 'method', type: 'string', isNullable: false),
      ];

      // distinct list instances with equal content should be equal
      const e1 = AnalyticsEvent(
        name: 'login',
        description: 'User logs in',
        parameters: paramsA,
      );
      const e2 = AnalyticsEvent(
        name: 'login',
        description: 'User logs in',
        parameters: paramsB,
      );

      expect(e1, equals(e2));

      // differing nested parameter values make events unequal
      const paramsC = [
        AnalyticsParameter(
            name: 'method',
            type: 'string',
            isNullable: false,
            allowedValues: ['A']),
      ];
      const e3 = AnalyticsEvent(
        name: 'login',
        description: 'User logs in',
        parameters: paramsC,
      );

      expect(e1, isNot(equals(e3)));
    });

    test('AnalyticsDomain toString shows event and parameter counts', () {
      const event1 = AnalyticsEvent(
        name: 'login',
        description: 'User logs in',
        parameters: [
          AnalyticsParameter(name: 'method', type: 'string', isNullable: false),
          AnalyticsParameter(name: 'source', type: 'string', isNullable: true),
        ],
      );

      const event2 = AnalyticsEvent(
        name: 'purchase',
        description: 'User makes purchase',
        parameters: [
          AnalyticsParameter(name: 'price', type: 'double', isNullable: false),
        ],
      );

      const domain = AnalyticsDomain(name: 'auth', events: [event1, event2]);

      expect(domain.eventCount, equals(2));
      expect(domain.parameterCount, equals(3));
      expect(domain.toString(), equals('auth (2 events, 3 parameters)'));
    });

    test('AnalyticsDomain equality depends on event replacement and order', () {
      const e1 = AnalyticsEvent(
        name: 'one',
        description: 'One',
        parameters: [],
      );
      const e2 = AnalyticsEvent(
        name: 'two',
        description: 'Two',
        parameters: [],
      );

      const d1 = AnalyticsDomain(name: 'n', events: [e1, e2]);
      const d2 = AnalyticsDomain(name: 'n', events: [e1, e2]);
      const d3 = AnalyticsDomain(name: 'n', events: [e2, e1]);

      expect(d1, equals(d2));
      expect(d1.hashCode, equals(d2.hashCode));
      // order matters
      expect(d1, isNot(equals(d3)));

      // replacement changes event equality and thus domain equality
      const e2v2 = AnalyticsEvent(
        name: 'two',
        description: 'Two',
        parameters: [],
        replacement: 'n.two_v2',
      );

      const d4 = AnalyticsDomain(name: 'n', events: [e1, e2v2]);
      expect(d1, isNot(equals(d4)));
    });
  });
}
