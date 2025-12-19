# Testing Guide

This guide covers pragmatic testing patterns for projects that use `analytics_gen`.

## What to test (and what not to)

- Test your **instrumentation logic** (what events fire, with which parameters).
- Do not unit-test third-party analytics SDKs — test your provider adapter/wrapper instead.
- Prefer **unit tests** with `MockAnalyticsService` over widget tests for analytics.

## Recommended patterns

### 1) Pure DI (no singleton)

If you inject analytics, tests stay isolated without global state:

```dart
final mock = MockAnalyticsService();
final analytics = Analytics(mock); // generated Analytics class in your app

// Act
analytics.logAuthLogin(method: 'email');

// Assert
expect(mock.records.single.name, 'auth_login');
```

### 2) Singleton usage (reset between tests)

If your app uses `Analytics.initialize(...)`, keep tests hermetic:

```dart
late MockAnalyticsService mock;

setUp(() {
  mock = MockAnalyticsService();
  Analytics.initialize(mock);
});

tearDown(() {
  Analytics.reset(); // generated helper
});
```

Then assert against `mock.records` (typed) or `mock.events` (legacy maps).

### 3) Awaitable providers (async flush)

If you buffer or queue events, verify that tests can await delivery:

```dart
final mock = MockAnalyticsService();
final async = AsyncAnalyticsAdapter(mock);
final batching = BatchingAnalytics(delegate: async);

Analytics.initialize(batching);
// ... act ...
await batching.flush();
```

## Typed matchers (optional)

Enable `test_matchers` in `analytics_gen.yaml` to generate matchers that make
assertions more readable in `package:test`.

## Common pitfalls

- Forgetting to call `Analytics.reset()` between tests (singleton state leaks).
- Asserting against untyped maps when `RecordedAnalyticsEvent` is available.
- Mixing dynamic event names with `strict_event_names` enabled (blocked by default).

