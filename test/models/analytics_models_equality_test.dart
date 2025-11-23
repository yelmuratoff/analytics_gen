import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';
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

    test('AnalyticsParameter equality considers all fields', () {
      final a = AnalyticsParameter(
        name: 'param',
        type: 'string',
        isNullable: false,
        regex: r'^[a-z]+$',
        minLength: 5,
        maxLength: 20,
        min: 1,
        max: 100,
        meta: {'key': 'value'},
        operations: ['set', 'increment'],
      );
      final b = AnalyticsParameter(
        name: 'param',
        type: 'string',
        isNullable: false,
        regex: r'^[a-z]+$',
        minLength: 5,
        maxLength: 20,
        min: 1,
        max: 100,
        meta: {'key': 'value'},
        operations: ['set', 'increment'],
      );

      // Test equality with identical values
      expect(a == b, isTrue);
      expect(a.hashCode, equals(b.hashCode));

      // Test inequality with different regex
      final c = AnalyticsParameter(
        name: 'param',
        type: 'string',
        isNullable: false,
        regex: r'^[A-Z]+$', // Different regex
        minLength: 5,
        maxLength: 20,
        min: 1,
        max: 100,
        meta: {'key': 'value'},
        operations: ['set', 'increment'],
      );
      expect(a == c, isFalse);

      // Test inequality with different minLength
      final d = AnalyticsParameter(
        name: 'param',
        type: 'string',
        isNullable: false,
        regex: r'^[a-z]+$',
        minLength: 10, // Different minLength
        maxLength: 20,
        min: 1,
        max: 100,
        meta: {'key': 'value'},
        operations: ['set', 'increment'],
      );
      expect(a == d, isFalse);

      // Test inequality with different maxLength
      final e = AnalyticsParameter(
        name: 'param',
        type: 'string',
        isNullable: false,
        regex: r'^[a-z]+$',
        minLength: 5,
        maxLength: 25, // Different maxLength
        min: 1,
        max: 100,
        meta: {'key': 'value'},
        operations: ['set', 'increment'],
      );
      expect(a == e, isFalse);

      // Test inequality with different min
      final f = AnalyticsParameter(
        name: 'param',
        type: 'string',
        isNullable: false,
        regex: r'^[a-z]+$',
        minLength: 5,
        maxLength: 20,
        min: 2, // Different min
        max: 100,
        meta: {'key': 'value'},
        operations: ['set', 'increment'],
      );
      expect(a == f, isFalse);

      // Test inequality with different max
      final g = AnalyticsParameter(
        name: 'param',
        type: 'string',
        isNullable: false,
        regex: r'^[a-z]+$',
        minLength: 5,
        maxLength: 20,
        min: 1,
        max: 200, // Different max
        meta: {'key': 'value'},
        operations: ['set', 'increment'],
      );
      expect(a == g, isFalse);

      // Test inequality with different meta
      final h = AnalyticsParameter(
        name: 'param',
        type: 'string',
        isNullable: false,
        regex: r'^[a-z]+$',
        minLength: 5,
        maxLength: 20,
        min: 1,
        max: 100,
        meta: {'key': 'different'}, // Different meta
        operations: ['set', 'increment'],
      );
      expect(a == h, isFalse);

      // Test inequality with different operations
      final i = AnalyticsParameter(
        name: 'param',
        type: 'string',
        isNullable: false,
        regex: r'^[a-z]+$',
        minLength: 5,
        maxLength: 20,
        min: 1,
        max: 100,
        meta: {'key': 'value'},
        operations: ['get', 'set'], // Different operations
      );
      expect(a == i, isFalse);
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

    test('AnalyticsEvent equality considers all fields', () {
      const params = [
        AnalyticsParameter(
          name: 'method',
          type: 'string',
          isNullable: false,
        ),
      ];

      final event1 = AnalyticsEvent(
        name: 'login',
        description: 'User logs in',
        parameters: params,
        meta: {'owner': 'team'},
        sourcePath: 'events/auth.yaml',
        lineNumber: 10,
      );
      final event2 = AnalyticsEvent(
        name: 'login',
        description: 'User logs in',
        parameters: params,
        meta: {'owner': 'team'},
        sourcePath: 'events/auth.yaml',
        lineNumber: 10,
      );

      expect(event1 == event2, isTrue);
      expect(event1.hashCode, equals(event2.hashCode));

      // Test inequality with different meta
      final event3 = AnalyticsEvent(
        name: 'login',
        description: 'User logs in',
        parameters: params,
        meta: {'owner': 'different'}, // Different meta
        sourcePath: 'events/auth.yaml',
        lineNumber: 10,
      );
      expect(event1 == event3, isFalse);

      // Test inequality with different sourcePath
      final event4 = AnalyticsEvent(
        name: 'login',
        description: 'User logs in',
        parameters: params,
        meta: {'owner': 'team'},
        sourcePath: 'events/other.yaml', // Different sourcePath
        lineNumber: 10,
      );
      expect(event1 == event4, isFalse);

      // Test inequality with different lineNumber
      final event5 = AnalyticsEvent(
        name: 'login',
        description: 'User logs in',
        parameters: params,
        meta: {'owner': 'team'},
        sourcePath: 'events/auth.yaml',
        lineNumber: 20, // Different lineNumber
      );
      expect(event1 == event5, isFalse);
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
