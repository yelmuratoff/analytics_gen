# Onboarding Guide

This guide is the fast path for engineers joining a project that uses `analytics_gen`. It keeps the busywork predictable—define your plan once, run the generator with the same flags as everyone else, and treat the generated code as part of your review surface.

## Prerequisites

- Dart SDK 3.3+ with `dart` on your PATH.
- `analytics_gen` listed under `dev_dependencies` in `pubspec.yaml`.
- Access to the repository so you can read `events/*.yaml` and `analytics_gen.yaml`.

### Optional: Kick the tires with the example app

If you have not seen the output before, run the bundled sample first:

```bash
cd example
dart pub get
dart run analytics_gen:generate --docs --exports
dart run lib/main.dart
```

This mirrors the workflow you will follow in your app and gives you a safe sandbox to inspect generated files before editing production YAML.

## Step 1 – Describe the tracking plan

1. Create or update the domain file under `events/`. Each file covers one domain (e.g., `auth.yaml`, `screen.yaml`) and should use snake_case keys unless your team intentionally opts out via naming config.
2. Keep every event documented: `description`, parameter docs, `deprecated` and `replacement` when you are sunsetting an event.
3. Treat nullable parameters explicitly with the `?` suffix (`string?`) so the generated API prevents mistakes.

Example (`events/auth.yaml`):

```yaml
auth:
  login:
    description: User logs in
    parameters:
      method:
        type: string
        description: Login method (email, google, apple)
  logout:
    description: User logs out
    parameters: {}
```

## Step 2 – Configure once, reuse everywhere

`analytics_gen.yaml` is the source of truth for generator behavior. Commit it and do not rely on local flags. A minimal config:

```yaml
analytics_gen:
  events_path: events
  output_path: lib/src/analytics/generated
  docs_path: docs/analytics_events.md
  exports_path: assets/generated
  generate_docs: true
  generate_json: true
  naming:
    enforce_snake_case_domains: true
    enforce_snake_case_parameters: true
```

- Use `domain_aliases` or per-parameter `identifier` overrides when legacy naming collides with snake_case rules.
- Avoid ad-hoc overrides in local scripts—CI should run exactly the same configuration.

## Step 3 – Generate artifacts

```bash
dart run analytics_gen:generate --docs --exports
```

Important variations:

- `--validate-only` – parse YAML and fail fast without writing files.
- `--no-docs` / `--no-exports` – temporarily skip heavy outputs when iterating locally.
- `--watch` – regenerate automatically during local development.

Outputs intentionally deterministic:

```
lib/src/analytics/generated/
├── analytics.dart          # Singleton + runtime plan
├── generated_events.dart   # Barrel export
└── events/                 # One mixin per domain
```

## Step 4 – Initialize and use the API

```dart
import 'src/analytics/generated/analytics.dart';

void bootstrapAnalytics() {
  Analytics.initialize(MultiProviderAnalytics([
    FirebaseAnalyticsService(firebase),
    AmplitudeService(amplitude),
  ]));
}

Future<void> login(String method) async {
  Analytics.instance.logAuthLogin(method: method);
}
```

- Initialization is mandatory. Accessing `Analytics.instance` before `initialize` throws a descriptive `StateError`.
- In tests, wire `MockAnalyticsService` or the async adapter to assert on recorded events.
- Logging stays synchronous by design. If a provider requires awaiting (network flushes, background isolates), wrap it in a queue that implements `IAnalytics` and delegates to `IAsyncAnalytics` (for example, via `AsyncAnalyticsAdapter`). This keeps feature code fire-and-forget while still letting you `await queue.flush()` in teardown hooks or integration tests.

## Step 5 – Review generated artifacts

1. Generated Dart (`lib/src/analytics/generated`) – diff should reflect only intentional plan edits. Look for renamed identifiers, parameter type shifts, or removed mixin methods that might break runtime assumptions.
2. Docs (`docs/analytics_events.md`) – fingerprint + totals must change only when YAML changes. Ensure descriptions stay informative and status (active/deprecated) is correct.
3. Exports (`assets/generated/*`) – CSV/JSON/SQL/SQLite outputs are consumed by stakeholders; verify column additions, identifier changes, and plan metadata.

Use the [Code Review checklist](./CODE_REVIEW.md) during PRs so instrumentation stays compliant.

## Troubleshooting

- Run `dart run analytics_gen:generate --plan` to inspect the parsed plan when something looks wrong.
- See [Validation & Naming](./VALIDATION.md) for common schema errors and the rationale behind strict identifiers.
- For capability questions (provider-specific APIs such as user properties), start with [Capabilities](./CAPABILITIES.md).

## Local Quality Gate

Before opening a PR:

1. `dart run analytics_gen:generate --docs --exports`
2. `dart analyze`
3. `dart test`
4. Re-run generation until there are no unexpected diffs

This loop keeps CI green and ensures analytics, docs, and exports stay in sync.
