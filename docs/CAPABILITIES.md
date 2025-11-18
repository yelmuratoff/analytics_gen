# Capabilities

Capabilities let analytics providers expose advanced features (user properties, revenue APIs, timed events) without polluting the core `IAnalytics.logEvent` contract. Think of them as optional add-ons: consumers ask for a capability when they need it, providers opt in only when they can implement it.

## Why not just add more methods to `IAnalytics`?

Adding provider-specific calls (`setUserProperty`, `logRevenue`, `setPushToken`, …) directly to `IAnalytics` violates SOLID:

- **Single Responsibility** – `IAnalytics` would have to change every time one team wants a new helper.
- **Interface Segregation** – implementers would be forced to stub methods they do not support.
- **Dependency Inversion** – app code would depend on concrete provider details.

Capabilities keep the generated API minimal (`logEvent` stays simple) while still giving teams access to richer SDK hooks.

## Key Types

| Type | Purpose |
| --- | --- |
| `AnalyticsCapability` | Marker interface implemented by capability objects. |
| `CapabilityKey<T>` | Typed key that prevents accidental mismatches. |
| `AnalyticsCapabilityProvider` | Provider interface that exposes a `capabilityResolver`. |
| `CapabilityRegistry` | Helper that stores capabilities by key. |

## Flow Overview

1. Define a capability interface describing the extra behavior.
2. Register an implementation inside your analytics provider.
3. Request the capability from `Analytics.instance` wherever you need it.

## Step-by-step Example

### 1. Define the capability + key

```dart
abstract class UserPropertiesCapability implements AnalyticsCapability {
  void setUserProperty(String name, String value);
  void clearUserProperty(String name);
}

const userPropertiesKey =
    CapabilityKey<UserPropertiesCapability>('user_properties');

abstract class RevenueCapability implements AnalyticsCapability {
  void logRevenue({
    required String productId,
    required double value,
    String? currency,
  });
}

const revenueKey = CapabilityKey<RevenueCapability>('revenue');

abstract class PushTokenCapability implements AnalyticsCapability {
  Future<void> setPushToken(String token);
}

const pushTokenKey = CapabilityKey<PushTokenCapability>('push_tokens');
```

### 2. Expose it from a provider

```dart
class FirebaseAnalyticsService
    implements IAnalytics, AnalyticsCapabilityProvider {
  final FirebaseAnalytics _firebase;
  final CapabilityRegistry _capabilities = CapabilityRegistry();

  FirebaseAnalyticsService(this._firebase) {
    _capabilities
      ..register(userPropertiesKey, _FirebaseUserProperties(_firebase))
      ..register(revenueKey, _FirebaseRevenue(_firebase))
      ..register(pushTokenKey, _FirebasePushTokens(_firebase));
  }

  @override
  void logEvent({required String name, AnalyticsParams? parameters}) {
    _firebase.logEvent(name: name, parameters: parameters);
  }

  @override
  AnalyticsCapabilityResolver get capabilityResolver => _capabilities;
}

final class _FirebaseUserProperties implements UserPropertiesCapability {
  final FirebaseAnalytics _firebase;
  _FirebaseUserProperties(this._firebase);

  @override
  void setUserProperty(String name, String value) =>
      _firebase.setUserProperty(name: name, value: value);

  @override
  void clearUserProperty(String name) =>
      _firebase.setUserProperty(name: name, value: null);
}

final class _FirebaseRevenue implements RevenueCapability {
  final FirebaseAnalytics _firebase;
  _FirebaseRevenue(this._firebase);

  @override
  void logRevenue({
    required String productId,
    required double value,
    String? currency,
  }) {
    _firebase.logEvent(
      name: 'revenue',
      parameters: {
        'product_id': productId,
        'value': value,
        if (currency != null) 'currency': currency,
      },
    );
  }
}

final class _FirebasePushTokens implements PushTokenCapability {
  final FirebaseAnalytics _firebase;
  _FirebasePushTokens(this._firebase);

  @override
  Future<void> setPushToken(String token) =>
      _firebase.setPushToken(token);
}
```

- Register as many capabilities as you need: the registry is just a typed map.
- Providers that do not implement a capability simply omit registration—no stubs or empty implementations required.

### 3. Consume it in application code

```dart
void markPremiumUser() {
  final capability = Analytics.instance.capability(userPropertiesKey);
  capability?.setUserProperty('tier', 'gold');
}
```

- The `?` keeps calls safe when the capability is not available.
- Consider surfacing logs/metrics when a capability is unexpectedly missing so you can catch misconfigured providers early.

## Tips for Explaining to Junior Engineers

- Compare capabilities to feature flags: only providers that implement the feature will expose it; everyone else keeps the simpler interface.
- Highlight that capabilities are regular Dart objects—no reflection or code generation.
- Emphasize testing: wire `MockAnalyticsService` with a fake capability to assert behavior in unit tests.

### Naming Capabilities Consistently

- Use `lowerCamelCase` for the constant (`userPropertiesKey`) and give it a descriptive string identifier (`'user_properties'`). This matches Dart style guidelines and keeps IDE auto-complete predictable.
- For teams that prefer screaming snake case, pick one convention and hold the line—`user_propertiesKey` vs `USER_PROPERTIES_KEY` mismatches make diffs noisy.
- Align capability interface names with domain language (`UserPropertiesCapability`, `RevenueCapability`, `PushTokenCapability`). Avoid generic labels like `ExtraCapability`.
- Document every capability key in the provider module so newcomers know what exists already before adding duplicates.

## Testing Patterns

```dart
class FakeCapabilityProvider extends MockAnalyticsService
    implements AnalyticsCapabilityProvider {
  final CapabilityRegistry _registry = CapabilityRegistry();

  FakeCapabilityProvider() {
    _registry.register(userPropertiesKey, _FakeUserProps());
  }

  @override
  AnalyticsCapabilityResolver get capabilityResolver => _registry;
}
```

Inject `FakeCapabilityProvider` in tests and assert that the capability methods were invoked when expected.

## Observability

When using `MultiProviderAnalytics`, hook into `onProviderFailure` and `onError` callbacks. They also receive the provider identifiers so you can alert when a capability-backed call fails (for instance, user property updates failing on one provider but not another).

## Next Steps

- Read the [Onboarding Guide](./ONBOARDING.md) if you are wiring the generator for the first time.
- Follow the [Code Review checklist](./CODE_REVIEW.md) when verifying new capabilities in PRs (pay special attention to provider registration and generated method usage).
