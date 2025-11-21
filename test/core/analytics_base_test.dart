import 'package:analytics_gen/src/core/analytics_base.dart';
import 'package:analytics_gen/src/core/analytics_capabilities.dart';
import 'package:analytics_gen/src/core/analytics_interface.dart';
import 'package:test/test.dart';

void main() {
  group('AnalyticsBase', () {
    test('capabilities getter returns NullCapabilityResolver by default', () {
      final base = _TestAnalyticsBase();

      expect(base.capabilities, isA<NullCapabilityResolver>());
    });

    test('capability helper delegates to capabilities resolver', () {
      final base = _TestAnalyticsBase();

      // Since it returns NullCapabilityResolver, getCapability should return null
      final result = base.capability(_TestCapability.key);

      expect(result, isNull);
    });
  });

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

class _TestAnalyticsBase extends AnalyticsBase {
  @override
  IAnalytics get logger => _StubAnalytics();
}

class _StubAnalytics implements IAnalytics {
  @override
  void logEvent({required String name, AnalyticsParams? parameters}) {}
}

class _TestCapability implements AnalyticsCapability {
  static const key = CapabilityKey<_TestCapability>('test');
}
