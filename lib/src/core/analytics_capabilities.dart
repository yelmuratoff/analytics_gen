import 'analytics_interface.dart';

/// Marker interface implemented by provider-specific capability objects.
abstract interface class AnalyticsCapability {}

/// Strongly typed key used to look up [AnalyticsCapability] instances.
final class CapabilityKey<T extends AnalyticsCapability> {
  /// Creates a new capability key.
  const CapabilityKey(this.name);

  /// The unique name of the capability.
  final String name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CapabilityKey<T> && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'CapabilityKey<$T>($name)';
}

/// Resolves provider-specific capabilities by [CapabilityKey].
abstract interface class AnalyticsCapabilityResolver {
  /// Returns the capability registered under [key] or `null` if not available.
  T? getCapability<T extends AnalyticsCapability>(CapabilityKey<T> key);
}

/// Providers implement this interface to surface their available capabilities.
abstract interface class AnalyticsCapabilityProvider {
  /// The resolver that provides access to capabilities.
  AnalyticsCapabilityResolver get capabilityResolver;
}

/// Empty resolver used when a provider does not support any capabilities.
class NullCapabilityResolver implements AnalyticsCapabilityResolver {
  /// Creates a new null resolver.
  const NullCapabilityResolver();

  @override
  T? getCapability<T extends AnalyticsCapability>(CapabilityKey<T> key) => null;
}

/// Mutable registry that providers can use to register their capabilities.
class CapabilityRegistry implements AnalyticsCapabilityResolver {
  /// Creates a new capability registry.
  CapabilityRegistry({
    Map<CapabilityKey<Object?>, AnalyticsCapability>? seed,
  }) : _capabilities = Map<CapabilityKey<Object?>, AnalyticsCapability>.from(
          seed ?? const <CapabilityKey<Object?>, AnalyticsCapability>{},
        );

  final Map<CapabilityKey<Object?>, AnalyticsCapability> _capabilities;

  /// Registers a capability under the provided [key].
  void register<T extends AnalyticsCapability>(
    CapabilityKey<T> key,
    T capability,
  ) {
    _capabilities[key] = capability;
  }

  @override
  T? getCapability<T extends AnalyticsCapability>(CapabilityKey<T> key) {
    final capability = _capabilities[key];
    if (capability == null) return null;
    return capability as T;
  }
}

const NullCapabilityResolver _nullCapabilityResolver = NullCapabilityResolver();

/// Returns the [AnalyticsCapabilityResolver] exposed by [analytics].
AnalyticsCapabilityResolver analyticsCapabilitiesFor(IAnalytics analytics) {
  if (analytics is AnalyticsCapabilityProvider) {
    final provider = analytics as AnalyticsCapabilityProvider;
    return provider.capabilityResolver;
  }
  return _nullCapabilityResolver;
}

/// Mixin that wires capability registration into provider implementations.
mixin CapabilityProviderMixin implements AnalyticsCapabilityProvider {
  final CapabilityRegistry _capabilityRegistry = CapabilityRegistry();

  @override
  AnalyticsCapabilityResolver get capabilityResolver => _capabilityRegistry;

  /// Registers [capability] under the provided [key].
  ///
  /// Call this from your provider constructor (or factory) to expose the
  /// capabilities you support.
  void registerCapability<T extends AnalyticsCapability>(
    CapabilityKey<T> key,
    T capability,
  ) {
    _capabilityRegistry.register(key, capability);
  }
}
