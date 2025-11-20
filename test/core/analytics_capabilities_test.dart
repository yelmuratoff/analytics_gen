import 'package:analytics_gen/analytics_gen.dart';
import 'package:test/test.dart';

final class _TestCapability implements AnalyticsCapability {
  final String value;
  _TestCapability(this.value);
}

const _testCapabilityKey = CapabilityKey<_TestCapability>('test_capability');

void main() {
  group('CapabilityRegistry', () {
    test('registers and resolves capability instances', () {
      final registry = CapabilityRegistry();
      final capability = _TestCapability('value');

      registry.register(_testCapabilityKey, capability);

      expect(registry.getCapability(_testCapabilityKey), same(capability));
    });

    test('returns null when capability missing', () {
      final registry = CapabilityRegistry();

      expect(registry.getCapability(_testCapabilityKey), isNull);
    });
  });

  group('analyticsCapabilitiesFor', () {
    test('returns provider resolver when implemented', () {
      final mock = MockAnalyticsService();
      final capability = _TestCapability('provider');
      mock.registerCapability(_testCapabilityKey, capability);

      final resolver = analyticsCapabilitiesFor(mock);

      expect(resolver.getCapability(_testCapabilityKey), same(capability));
    });

    test('returns null resolver when provider lacks capabilities', () {
      final resolver = analyticsCapabilitiesFor(_LoggerOnly());

      expect(resolver.getCapability(_testCapabilityKey), isNull);
    });
  });

  group('MultiProviderAnalytics capability resolution', () {
    test('surfaces capability from the first provider that supplies it', () {
      final primary = MockAnalyticsService();
      final secondary = MockAnalyticsService();
      secondary.registerCapability(_testCapabilityKey, _TestCapability('ok'));

      final multi = MultiProviderAnalytics([primary, secondary]);

      final resolved =
          multi.capabilityResolver.getCapability(_testCapabilityKey);
      expect(resolved, isNotNull);
      expect(resolved!.value, equals('ok'));
    });
  });

  group('AnalyticsBase.capability helper', () {
    test('delegates to resolver and returns typed capability', () {
      final registry = CapabilityRegistry();
      final capability = _TestCapability('helper');
      registry.register(_testCapabilityKey, capability);

      final analytics = _AnalyticsHarness(registry);

      expect(analytics.capability(_testCapabilityKey), same(capability));
    });
  });
}

final class _LoggerOnly implements IAnalytics {
  @override
  void logEvent({required String name, AnalyticsParams? parameters}) {}
}

final class _AnalyticsHarness extends AnalyticsBase {
  final AnalyticsCapabilityResolver resolver;

  _AnalyticsHarness(this.resolver);

  @override
  IAnalytics get logger => _LoggerOnly();

  @override
  AnalyticsCapabilityResolver get capabilities => resolver;
}
