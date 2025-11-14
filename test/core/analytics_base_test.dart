import 'package:analytics_gen/src/core/analytics_base.dart';
import 'package:analytics_gen/src/core/analytics_interface.dart';
import 'package:test/test.dart';

void main() {
  group('ensureAnalyticsInitialized', () {
    test('returns analytics when initialized', () {
      final analytics = _StubAnalytics();

      final result = ensureAnalyticsInitialized(analytics);

      expect(result, same(analytics));
    });

    test('throws descriptive StateError when not initialized', () {
      expect(
        () => ensureAnalyticsInitialized(null),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Analytics.initialize'),
          ),
        ),
      );
    });
  });
}

class _StubAnalytics implements IAnalytics {
  @override
  void logEvent({required String name, AnalyticsParams? parameters}) {}
}
