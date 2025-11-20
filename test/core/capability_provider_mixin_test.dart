import 'package:analytics_gen/src/core/analytics_capabilities.dart';
import 'package:analytics_gen/src/core/analytics_interface.dart';
import 'package:test/test.dart';

void main() {
  group('CapabilityProviderMixin', () {
    test('exposes registered capabilities via analyticsCapabilitiesFor', () {
      final provider = _FakeAnalyticsProvider();

      final capability = analyticsCapabilitiesFor(provider).getCapability(
        _fakeCapabilityKey,
      );

      expect(capability, isA<_FakeCapability>());
      expect(capability!.label, equals('ready'));
    });

    test('registerCapability can be invoked multiple times', () {
      final provider = _FakeAnalyticsProvider();
      provider.registerCapability(_secondCapabilityKey, _FakeCapability('two'));

      final resolver = analyticsCapabilitiesFor(provider);

      expect(resolver.getCapability(_fakeCapabilityKey), isNotNull);
      expect(resolver.getCapability(_secondCapabilityKey)?.label, 'two');
    });
  });
}

const _fakeCapabilityKey =
    CapabilityKey<_FakeCapability>('test.fakeCapability');
const _secondCapabilityKey =
    CapabilityKey<_FakeCapability>('test.secondCapability');

final class _FakeAnalyticsProvider
    with CapabilityProviderMixin
    implements IAnalytics {
  _FakeAnalyticsProvider() {
    registerCapability(_fakeCapabilityKey, const _FakeCapability('ready'));
  }

  @override
  void logEvent({required String name, AnalyticsParams? parameters}) {}
}

final class _FakeCapability implements AnalyticsCapability {
  const _FakeCapability(this.label);

  final String label;
}
