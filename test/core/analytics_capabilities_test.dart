import 'package:analytics_gen/analytics_gen.dart';
import 'package:test/test.dart';

final class _TestCapability implements AnalyticsCapability {
  _TestCapability(this.value);
  final String value;
}

final class _OtherCapability implements AnalyticsCapability {}

const _testCapabilityKey = CapabilityKey<_TestCapability>('test_capability');

void main() {
  group('CapabilityKey', () {
    test('== returns true for identical instances', () {
      const key1 = CapabilityKey<_TestCapability>('test');
      const key2 = CapabilityKey<_TestCapability>('test');

      expect(key1 == key2, isTrue);
    });

    test('== returns false for different names', () {
      const key1 = CapabilityKey<_TestCapability>('test1');
      const key2 = CapabilityKey<_TestCapability>('test2');

      expect(key1 == key2, isFalse);
    });

    test('== returns false for different types', () {
      const key1 = CapabilityKey<_TestCapability>('test');
      const key2 = CapabilityKey<AnalyticsCapability>('test');

      expect(key1 == key2, isFalse);
    });

    test('hashCode is consistent with ==', () {
      const key1 = CapabilityKey<_TestCapability>('test');
      const key2 = CapabilityKey<_TestCapability>('test');
      const key3 = CapabilityKey<_TestCapability>('other');

      expect(key1.hashCode, equals(key2.hashCode));
      expect(key1.hashCode, isNot(equals(key3.hashCode)));
    });

    test('toString includes type and name', () {
      const key = CapabilityKey<_TestCapability>('my_key');

      expect(key.toString(), equals('CapabilityKey<_TestCapability>(my_key)'));
    });
  });

  group('CapabilityRegistry', () {
    test('registers and resolves capability instances', () {
      final registry = CapabilityRegistry();
      final capability = _TestCapability('value');

      registry.register(_testCapabilityKey, capability);

      expect(registry.getCapability(_testCapabilityKey), same(capability));
    });

    test('throws StateError when capability has wrong type', () {
      final registry = CapabilityRegistry();
      // Register a legitimate capability
      final capability = _TestCapability('valid');
      registry.register(_testCapabilityKey, capability);

      // Create a key with the SAME name but DIFFERENT type
      // explicit cast to avoid 'const' if necessary or just a new key
      const collisionKey = CapabilityKey<_OtherCapability>('test_capability');

      // Attempt to retrieve using the collision key.
      // The registry has 'test_capability' -> _TestCapability
      // We ask for 'test_capability' -> _OtherCapability
      // The runtime check "capability is! T" (is! _OtherCapability) should pass -> Throw StateError
      expect(
        () => registry.getCapability(collisionKey),
        throwsStateError,
      );
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
  _AnalyticsHarness(this.resolver);
  final AnalyticsCapabilityResolver resolver;

  @override
  IAnalytics get logger => _LoggerOnly();

  @override
  AnalyticsCapabilityResolver get capabilities => resolver;
}
