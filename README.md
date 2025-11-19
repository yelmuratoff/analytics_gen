<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/analytics_gen.png?raw=true" width="400">

  <p><strong>Type-safe analytics events from a single YAML source of truth.</strong></p>

  <p>
    <a href="https://pub.dev/packages/analytics_gen">
      <img src="https://img.shields.io/pub/v/analytics_gen?include_prereleases&style=for-the-badge&logo=flutter&labelColor=000000&color=DF4926" alt="pub version">
    </a>
    <a href="https://opensource.org/licenses/Apache-2.0">
      <img src="https://img.shields.io/badge/license-apache 2.0-blue?style=for-the-badge&logo=apache&labelColor=000000&color=DF4926" alt="License">
    </a>
    <a href="https://github.com/yelmuratoff/analytics_gen">
      <img src="https://img.shields.io/github/stars/yelmuratoff/analytics_gen?style=for-the-badge&logo=github&labelColor=000000&color=DF4926" alt="GitHub stars">
    </a>
    <a href="https://github.com/yelmuratoff/analytics_gen/actions/workflows/ci.yml">
      <img src="https://img.shields.io/github/actions/workflow/status/yelmuratoff/analytics_gen/ci.yml?branch=main&style=for-the-badge&logo=github&labelColor=000000" alt="CI status">
    </a>
    <a href="https://codecov.io/gh/yelmuratoff/analytics_gen">
      <img src="https://img.shields.io/codecov/c/github/yelmuratoff/analytics_gen?style=for-the-badge&logo=codecov&labelColor=000000" alt="coverage">
    </a>
  </p>

  <p>
    <a href="https://pub.dev/packages/analytics_gen/score">
      <img src="https://img.shields.io/pub/likes/analytics_gen?style=for-the-badge&logo=flutter&labelColor=000000&color=DF4926" alt="Pub likes">
    </a>
    <a href="https://pub.dev/packages/analytics_gen/score">
      <img src="https://img.shields.io/pub/points/analytics_gen?style=for-the-badge&logo=flutter&labelColor=000000&color=DF4926" alt="Pub points">
    </a>
    <a href="https://pub.dev/packages/analytics_gen/downloads">
      <img src="https://img.shields.io/pub/dm/analytics_gen?style=for-the-badge&logo=flutter&labelColor=000000&color=DF4926" alt="Pub downloads">
    </a>
  </p>
</div>

## Table of Contents

- [Overview](#overview)
- [TL;DR Quick Start](#tldr-quick-start)
- [Key Features](#key-features)
- [Architecture Snapshot](#architecture-snapshot)
- [Documentation Hub](#documentation-hub)
- [CLI Commands](#cli-commands)
- [Validation & Quality](#validation--quality)
- [Analytics Providers & Capabilities](#analytics-providers--capabilities)
- [Synchronous Logging & Async Providers](#synchronous-logging--async-providers)
- [Batch Logging Buffers](#batch-logging-buffers)
- [Example](#example)
- [Testing](#testing)
- [Contributing](#contributing)
- [FAQ](#faq)
- [License](#license)

## Overview

`analytics_gen` keeps your tracking plan, generated code, docs, and analytics providers in sync. Describe events once in YAML and the tool emits a type-safe Dart API, deterministic documentation, and optional exports (CSV/JSON/SQL/SQLite). The runtime `Analytics` singleton delegates to any provider(s) you register, so instrumentation stays consistent across platforms and teams.

## TL;DR Quick Start

1. **Describe events** in `events/*.yaml` (one domain per file). Keep descriptions + parameter docs current.
2. **Configure** `analytics_gen.yaml` so every machine runs the same generator settings.
3. **Generate** code/doc/exports with `dart run analytics_gen:generate --docs --exports`.
4. **Initialize + use** the generated API: `Analytics.initialize(...)`, then call the strongly typed mixins anywhere in your app.
5. **Review diffs** for generated Dart, docs, and exports during PRs—treat them as production code.

Need a detailed walkthrough? Head to [`docs/ONBOARDING.md`](docs/ONBOARDING.md).

## Key Features

- **Type-safe analytics** – compile-time event + parameter checking, optional allowed-value guards.
- **Domain-per-file generation** – readable diffs, mixins scoped to a single domain.
- **Deterministic outputs** – sorted parsing with fingerprints to keep reviewers sane.
- **Multi-provider fan-out** – send the same event to multiple SDKs with error handling.
- **Docs + exports** – Markdown, CSV, JSON, SQL, SQLite artifacts for stakeholders.
- **Runtime plan** – `Analytics.plan` exposes the parsed plan at runtime for debugging or feature toggles.

## Architecture Snapshot

```
lib/src/analytics/generated/
├── analytics.dart          # Singleton + runtime plan metadata
├── generated_events.dart   # Barrel export
└── events/
    ├── auth_events.dart    # AnalyticsAuth mixin
    ├── screen_events.dart  # AnalyticsScreen mixin
    └── purchase_events.dart
```

- Docs land in `docs/analytics_events.md`.
- Optional exports go under `assets/generated/`.
- Re-running the generator without YAML changes yields byte-identical files.

## Documentation Hub

- [Onboarding Guide](docs/ONBOARDING.md) – setup checklist, command reference, troubleshooting.
- [Validation & Naming](docs/VALIDATION.md) – schema, strict naming rules, and error explanations.
- [Capabilities](docs/CAPABILITIES.md) – why capability keys exist and how to expose provider-specific APIs without violating SOLID.
- [Migration Guides](docs/MIGRATION_GUIDES.md) – playbooks for moving Firebase manual strings, Amplitude events, and Mixpanel plans into YAML while keeping downstream dashboards stable.
- [Code Review checklist](docs/CODE_REVIEW.md) – what to inspect in YAML, generated code, docs, and provider adapters during PRs.
- [Scalability & Performance](docs/SCALABILITY.md) – benchmarks and limits for large enterprise plans (100+ domains / 1000+ events).

## CLI Commands

```bash
dart run analytics_gen:generate              # code only (default)
dart run analytics_gen:generate --docs       # code + docs
dart run analytics_gen:generate --docs --exports
dart run analytics_gen:generate --docs --no-code
dart run analytics_gen:generate --exports --no-code
dart run analytics_gen:generate --validate-only
dart run analytics_gen:generate --plan
dart run analytics_gen:generate --watch
```

Pair these with the configuration you committed to `analytics_gen.yaml`. Add `--no-docs` / `--no-exports` locally if you need a faster iteration loop—the config still drives CI.

## Validation & Quality

- Run `dart run analytics_gen:generate --validate-only` in CI to block invalid YAML before files are written.
- Naming strategy (`analytics_gen.naming`) enforces consistent identifiers—override per-field when legacy plans demand it.
- Docs/JSON/SQL outputs embed a fingerprint derived from the plan; unexpected diffs mean someone skipped regeneration.
- Full details live in [`docs/VALIDATION.md`](docs/VALIDATION.md).

## Analytics Providers & Capabilities

The generated mixins call `Analytics.instance.logEvent(...)`. You are in control of the underlying providers:

- Implement `IAnalytics` for a single SDK.
- Use `MultiProviderAnalytics` to fan out events while isolating provider failures.
- Need provider-specific hooks (user properties, timed events, etc.)? Register typed capabilities via `CapabilityKey<T>` (the new `CapabilityProviderMixin` wires a registry automatically). Consumers request them when needed, keeping the base interface small. See [`docs/CAPABILITIES.md`](docs/CAPABILITIES.md) for a junior-friendly walkthrough.

Mock + async adapters (`MockAnalyticsService`, `AsyncAnalyticsAdapter`) are included for tests and await-heavy flows.

## Synchronous Logging & Async Providers

`IAnalytics.logEvent` stays synchronous on purpose:

- UI instrumentation should be fire-and-forget so frames are never blocked by analytics I/O.
- Generated methods are widely sprinkled across apps; forcing `await` would leak runtime coupling into feature code.
- Tests remain simple because `MockAnalyticsService` records events immediately.

When a provider must await network flushes or heavy batching, queue that work behind an adapter instead of changing the base interface. A reference pattern:

```dart
final class QueueingAnalytics implements IAnalytics {
  QueueingAnalytics(this._asyncAnalytics);

  final IAsyncAnalytics _asyncAnalytics;
  final _pending = <Future<void>>[];

  @override
  void logEvent({required String name, AnalyticsParams? parameters}) {
    _pending.add(
      _asyncAnalytics.logEventAsync(name: name, parameters: parameters),
    );
  }

  Future<void> flush() => Future.wait(_pending);
}

final asyncProvider = AsyncAnalyticsAdapter(
  MultiProviderAnalytics([
    FirebaseAnalyticsService(firebase),
    AmplitudeService(amplitude),
  ]),
);

Analytics.initialize(QueueingAnalytics(asyncProvider));
```

- The UI still calls synchronous generated methods.
- `QueueingAnalytics` tracks outstanding futures so diagnostics/tests can `await` `flush()`.
- `AsyncAnalyticsAdapter` wires into existing synchronous providers, which keeps compatibility with code gen.

This same pattern appears in `example/lib/main.dart`, where the async adapter is exercised alongside the synchronous runtime.

## Batch Logging Buffers

When you need to control network fan-out—slow uplinks, cellular metering, or provider SDKs that enforce batch delivery—wrap your async provider with `BatchingAnalytics`.

```dart
final asyncAdapter = AsyncAnalyticsAdapter(
  MultiProviderAnalytics([
    FirebaseAnalyticsService(firebase),
    AmplitudeService(amplitude),
  ]),
);

final batching = BatchingAnalytics(
  delegate: asyncAdapter,
  maxBatchSize: 25,
  flushInterval: const Duration(seconds: 5),
  onFlushError: (error, stack) {
    print('Batch flush failed: $error');
  },
);

Analytics.initialize(batching);

// ... app runs, events buffer automatically.

Future<void> onAppBackground() async {
  await batching.flush(); // or await batching.dispose();
}
```

- `maxBatchSize` forces a flush when enough events accumulate.
- `flushInterval` (optional) drains on a timer for long-lived sessions.
- `flush()` returns a `Future` so lifecycle hooks (`AppLifecycleState.paused`, integration-test teardown) can wait for delivery.
- If the delegate throws, the batch is requeued and the optional `onFlushError` hook runs; call `flush()` again when the provider is ready.

Combine `BatchingAnalytics` with `AsyncAnalyticsAdapter` to await multiple providers without changing the generated, synchronous API surface.

## Example

The [`example/`](example/) directory shows a working tracking plan + app integration.

```bash
cd example
dart pub get
dart run analytics_gen:generate --docs --exports
dart run lib/main.dart
```

Generated artifacts inside the example mirror what your app will emit. Use it as a sandbox before editing your production plan. Prefer running the Flutter sample via `flutter run` so you can tap through the buttons and inspect recorded events live—the UI simply calls into a controller that wraps the generated mixins so logging stays out of widgets.

## Testing

- Unit tests should initialize `Analytics` with `MockAnalyticsService` (or the async adapter) and assert on recorded events.
- Add `dart run analytics_gen:generate --validate-only` to CI so schema errors fail fast.
- Run `dart analyze` + `dart test` before committing—analytics code follows the same standards as the rest of your Flutter/Dart app.

## Contributing

Contributions welcome! Please:

1. Fork the repo and open a PR with focused changes.
2. Add unit tests for new features/validations.
3. Run `dart analyze`, `dart test`, and the generator before submitting.
4. Document user-facing changes in the README or the relevant doc under `docs/`.

Every PR description flows through `.github/pull_request_template.md`, which links directly to [`docs/CODE_REVIEW.md`](docs/CODE_REVIEW.md). Walk through that checklist (YAML, generated Dart, docs/exports, providers, and security) before requesting a review so reviewers only need to validate, not rediscover, regressions.

## FAQ

- **Why YAML instead of defining events directly in Dart?**  
  YAML is tooling-agnostic and easy for product/analytics teams to edit. `analytics_gen` transforms it into code, docs, and exports without duplication.

- **Can I migrate existing events?**  
  Yes. Start by mirroring your current events in YAML, run the generator, and gradually replace hard-coded `logEvent` calls with generated methods.

- **Does this lock me into one provider?**  
  No. Implement or combine multiple providers. Capabilities expose provider-specific features without bloating the global interface.

- **Is it safe to commit generated files?**  
  Absolutely. Deterministic output keeps diffs readable. Reviewers should inspect code/docs/exports just like any other change (see [`docs/CODE_REVIEW.md`](docs/CODE_REVIEW.md)).

## License

Licensed under the Apache License, Version 2.0. See [`LICENSE`](LICENSE) for details.
