<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/analytics_gen.png?raw=true" width="400">

  <p><strong>Type‑safe analytics events from a single YAML source of truth.</strong></p>

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
- [Key features](#key-features)
- [When to use](#when-to-use)
- [Quick Start](#quick-start)
  - [Install](#1-install)
  - [Define events](#2-define-events-yaml-tracking-plan)
  - [Generate code](#3-generate-code)
- [Why this approach](#why-this-approach)
- [Configuration](#configuration)
- [YAML Schema](#yaml-schema)
- [Validation Guarantees](#validation-guarantees)
- [CLI quick commands](#cli-quick-commands)
- [Generated Files](#generated-files)
- [Analytics Providers](#analytics-providers)
- [Deterministic Output](#deterministic-output)
- [Testing](#testing)
- [Example](#example)
- [Contributing](#contributing)
- [FAQ](#faq)
- [License](#license)

## Onboarding Checklist

1. **Define** your events in `events/*.yaml` (one domain per file). Keep names snake_case unless you opt into overrides.
2. **Configure** `analytics_gen.yaml` (or use defaults) so everyone runs the same generator settings.
3. **Generate** code/docs/exports with `dart run analytics_gen:generate --docs --exports` (or the simple variant during local dev).
4. **Initialize + use** the generated API (`Analytics.initialize(...)` once, then call the strongly typed mixin methods).
5. **Review** the generated artifacts (`lib/src/analytics/generated`, docs, exports) during PRs to keep product + data teams in sync.

## Overview

`analytics_gen` keeps your tracking plan, generated code, and analytics providers in sync.

You describe events once in YAML; the package generates:

- A type‑safe Dart API for all events and parameters
- A single `Analytics` entrypoint with domain‑specific mixins
- Optional documentation and export files (CSV/JSON/SQL/SQLite)

This removes brittle, hand‑written string keys, prevents drift across platforms, and makes analytics changes safe to review and refactor from a single YAML source.

## Key features

- **Type‑safe analytics** - compile‑time checking of event names and parameter types
- **YAML → Dart generation** - write your plan once; emit strongly‑typed methods
- **Domain-per-file** - a clean file per domain for readable diffs and code review
- **Multi‑provider support** - fan‑out events to multiple analytics backends
- **Exports & docs** - optional CSV/JSON/SQL/SQLite and generated Markdown for stakeholders
- **Deterministic output** - fingerprinted and sorted generation prevents noisy diffs
- **Watch mode & cleanup** - safe incremental regeneration; outputs cleaned before emit
- **Runtime plan** - generated `Analytics.plan` makes plan metadata available at runtime

## When to use

- You maintain a growing tracking plan and want the plan to be reviewable and type‑safe
- Product, data, and engineering teams need a shared source of truth
- You send identical events to multiple analytics providers and want consistency
- You prefer compile‑time guarantees over stringly‑typed event names

## When it may not fit

- Small apps with very few events and no need for a shared tracking plan
- When you rely heavily on provider-specific SDK primitives that can't be generalized

## Quick Start

### 1. Install

Add `analytics_gen` to your `dev_dependencies` and get packages:

```yaml
dev_dependencies:
  analytics_gen: ^0.1.6
```

```bash
dart pub get
```

### 2. Define Events (YAML Tracking Plan)

Create `events/auth.yaml`:

```yaml
auth:
  login:
    description: "User logs in"
    parameters:
      method:
        type: string
        description: "Login method (email, google, apple)"

  logout:
    description: "User logs out"
    parameters: {}
```

To deprecate an event:

```yaml
auth:
  login:
    description: "User logs in"
    deprecated: true
    replacement: auth.login_v2
    parameters:
      method:
        type: string
        description: "Login method (email, google, apple)"
```

### 3. Generate Code

```bash
dart run analytics_gen:generate --docs --exports
```

This creates a stable, reviewable set of generated files:

Tip: run `dart run analytics_gen:generate --help` anytime to list CLI options and usage examples.

```
lib/src/analytics/generated/
├── analytics.dart              # Auto-generated singleton
├── generated_events.dart       # Barrel file (exports)
└── events/
    ├── auth_events.dart       # Auth domain events
    ├── screen_events.dart     # Screen domain events
    └── purchase_events.dart   # Purchase domain events
```

### 4. Use It in Your App

```dart
import 'package:analytics_gen/analytics_gen.dart';
import 'src/analytics/generated/analytics.dart';

void main() {
  // Initialize once
  Analytics.initialize(YourAnalyticsService());

  // Use anywhere in your app
  Analytics.instance.logAuthLogin(method: 'email');
  Analytics.instance.logAuthLogout();
}
```

> Important: accessing `Analytics.instance` before calling `Analytics.initialize` throws a descriptive `StateError`, keeping improper usage from silently failing.

## Onboarding Walkthrough

### Step 1 – Describe your tracking plan

Create or update the domain files under `events/`. Keep descriptions and parameter docs current:

```yaml
auth:
  signup:
    description: User creates a new account
    parameters:
      method: string
      referral_code:
        type: string?
        description: Optional referral code used during signup
```

### Step 2 – Configure once, run everywhere

`analytics_gen.yaml` captures paths, generators, and naming rules. Commit it so the whole team generates identical artifacts:

```yaml
analytics_gen:
  events_path: events
  output_path: src/analytics/generated
  generate_docs: true
  naming:
    enforce_snake_case_domains: true
    enforce_snake_case_parameters: true
```

### Step 3 – Generate artifacts

```bash
dart run analytics_gen:generate --docs --exports
```

- `lib/src/analytics/generated/analytics.dart` — singleton + mixins
- `docs/analytics_events.md` — Markdown docs (with fingerprint)
- `assets/generated/*` — CSV/JSON/SQL/SQLite exports (optional)

### Step 4 – Use the type-safe API

```dart
void main() {
  Analytics.initialize(MockAnalyticsService());
  Analytics.instance.logAuthSignup(method: 'email');
}
```

Need provider-specific features? Request the capability you registered on your provider:

```dart
final props = Analytics.instance.capability(userPropertiesKey);
props?.setUserProperty('premium_tier', 'gold');
```

### Step 5 – Read the generated code

- `analytics.dart` exposes `Analytics.plan` (runtime plan) and aggregates all mixins.
- `events/*_events.dart` documents every method signature next to its YAML description.
- Treat generated files as part of the review—they visualize the impact of YAML edits.

### Common validation errors

| Error | Why it happens | Fix |
| --- | --- | --- |
| `Domain "Auth" ... violates the configured naming strategy` | Domain keys must be snake_case when enforcement is on. | Rename to `auth` or disable `enforce_snake_case_domains` (only for legacy plans). |
| `Parameter identifier "userId" ... violates the configured naming strategy` | Identifiers default to snake_case. | Use `identifier: user_id` or disable parameter enforcement for that project. |
| `Duplicate analytics event identifier` | Two events resolve to the same canonical ID (`identifier` or template). | Provide unique `identifier` values or tweak `identifier_template`. |
| `Parameters ... must be a map` | YAML indentation/structure is invalid. | Ensure each event’s `parameters` key points to a map (use `{}` for none). |

Run `dart run analytics_gen:generate --validate-only` in CI to catch these issues before code generation.

## Why this approach

- **Readable** - domain-per-file keeps each area focused and reviewable
- **Maintainable** - changes to one domain aren't scattered across the codebase
- **Scalable** - new domains don't bloat a single generated file
- **Simple imports** - a barrel file provides one canonical import for generated events

## Configuration

Create `analytics_gen.yaml` in your project root (optional, with sensible defaults if omitted):

```yaml
analytics_gen:
  events_path: events                      # YAML event files location
  output_path: src/analytics/generated     # Generated code output
  docs_path: docs/analytics_events.md      # Documentation output
  exports_path: assets/generated           # Exports output
  generate_docs: true
  generate_csv: true
  generate_json: true
  generate_sql: true
  generate_plan: true
  # When true, event descriptions are included in the emitted
  # `logger.logEvent` parameters under the key `description`. Defaults to
  # `false`.
  # include_event_description: false
  naming:
    enforce_snake_case_domains: true       # Disable for legacy domain names
    enforce_snake_case_parameters: true    # Disable for legacy parameter keys
    event_name_template: '{domain}: {event}'
    identifier_template: '{domain}: {event}'
    domain_aliases:
      marketing: 'Marketing Domain'        # Used by {domain_alias} placeholder
```

When `generate_docs` or any export flag is enabled in the config, the CLI will run those generators automatically (no need to pass `--docs` or `--exports`). Use `--no-docs` or `--no-exports` to temporarily override config.

Set `generate_plan: false` if you prefer to omit the runtime `Analytics.plan` metadata from `analytics.dart`.

### Naming strategy

`analytics_gen` still defaults to snake_case everywhere, but the `naming` block gives you several customization points:

- Toggle `enforce_snake_case_domains` / `enforce_snake_case_parameters` off to ingest legacy camelCase or kebab-case plans without renaming every key. When disabled, validation focuses on the identifiers you provide instead of the raw YAML keys.
- `event_name_template` decides what gets logged whenever an event omits `event_name`. Use `{domain}`, `{domain_alias}`, and `{event}` placeholders; aliases come from `domain_aliases`.
- `identifier_template` defines the canonical ID that must stay unique across the plan. Override it globally or per event with the new `identifier` field to keep analytics strings and unique IDs decoupled.
- Add entries to `domain_aliases` to control how `{domain_alias}` renders inside templates (helpful when YAML keys are filesystem-safe but you want spaces/punctuation in exports).

## YAML Schema

### Basic Event

```yaml
domain_name:
  event_name:
    description: Event description
    parameters:
      param1: string
      param2: int
```

### Nullable Parameters

```yaml
auth:
  signup:
    description: User signs up
    parameters:
      referral_code: string?  # Optional parameter
```

### Parameters with Descriptions

```yaml
purchase:
  completed:
    description: Purchase completed
    parameters:
      product_id:
        type: string
        description: ID of purchased product
      price:
        type: double
        description: Purchase price
      method:
        type: string
        description: Payment method
        allowed_values: [card, paypal, apple_pay]
```

### Custom Event Names (for Legacy / External Systems)

```yaml
screen:
  view:
    description: Screen viewed
    event_name: "Screen: View"  # Custom name for legacy systems
    identifier: screen.view     # Optional canonical identifier
    parameters:
      screen_name: string
```

Note: you can include parameter placeholders in `event_name` that will be
replaced with the generated Dart parameter variables when code is emitted.
This makes it safe to include contextual values (like the active screen name)
in legacy or provider-specific strings while preserving a type-safe API.

Example with placeholder interpolation:

```yaml
screen:
  view:
    description: Screen viewed
    event_name: "Screen: {screen_name}"
    parameters:
      screen_name: string
      previous_screen:
        type: string?
        description: Name of the previous screen
      duration_ms:
        type: int?
        description: Time spent on previous screen in milliseconds
```

Generated Dart snippet (truncated):

```dart
void logScreenView({
  int? durationMs,
  String? previousScreen,
  required String screenName,
}) {
  logger.logEvent(
    name: "Screen: ${screenName}",
    parameters: <String, Object?>{
      if (durationMs != null) "duration_ms": durationMs,
      if (previousScreen != null) "previous_screen": previousScreen,
      "screen_name": screenName,
    },
  );
}
```

Notes & behavior:
- Placeholders are written in the YAML using `{parameter_name}` (snake_case).
- During generation the placeholder is replaced by the camelCase parameter
  variable (e.g. `{screen_name}` -> `${screenName}`) so you can use the
  variable directly in the emitted string.
- If a placeholder does not match any parameter name exactly, it is left
  unchanged so your logs are predictable and explicit validation is not
  attempted at generation time.
- This interpolation happens only in the generated Dart logger call — the
  raw `event_name` is still used for exports and documentation so your
  tracking plan remain unchanged.

### Parameter overrides (identifiers + wire names)

```yaml
auth:
  login:
    description: User logs in
    parameters:
      tracking_id:
        type: string
        identifier: trackingIdentifier   # Used for generated Dart APIs
        param_name: tracking-id          # Sent to analytics providers
```

- `identifier` lets you keep snake_case YAML while exposing a custom Dart-friendly parameter (`trackingIdentifier` above). Use it whenever the YAML key doesn't produce the method signature you need.
- `param_name` rewrites the actual analytics payload key so you can continue logging `tracking-id` (or any other legacy string) without sacrificing the clean YAML identifier.

### Supported Types

- `int`, `string`, `bool`, `double`, `float`
- `map` (Map<String, dynamic>)
- `list` (List<dynamic>)
- Add `?` for nullable: `string?`, `int?`
- Custom Dart types (e.g., `DateTime`, `Uri`, `MyEnum`) are emitted exactly as declared, so you retain compile-time checking without extra YAML tricks.

### Parameter Validation

- Declare `allowed_values` for a parameter to auto-generate a runtime guard that throws an `ArgumentError` if your app passes anything outside that list. This keeps your analytics payloads consistent with the tracking plan and surfaces mistakes during development (and CI when you run `dart test` or `dart run analytics_gen:generate`).
- Parameter identifiers are snake_case by default (lowercase letters, digits, underscores) and must remain unique even after camelCase normalization (e.g., `user_id` vs `user-id`). Disable `analytics_gen.naming.enforce_snake_case_parameters` or provide a per-parameter `identifier` when legacy plans need different conventions.

### Domain Naming

- Domain keys (top-level YAML keys) are snake_case by default to keep generated files filesystem-safe. Toggle `analytics_gen.naming.enforce_snake_case_domains` off when ingesting legacy domain names—the parser still preserves deterministic ordering and uniqueness via the identifier template.
- This keeps generated file and class names stable and filesystem‑safe.
- Each event's canonical identifier—either the optional `identifier` field or the configured `identifier_template`—must be unique across your entire tracking plan. Duplicate identifiers cause the parser to throw a `FormatException`, which surfaces immediately when you run the generator (including `--validate-only`), preventing conflicting analytics payloads from being emitted even if their provider-facing `event_name` strings are the same.

## Validation Guarantees

- `dart run analytics_gen:generate --validate-only` (or any run that parses your YAML) enforces the same identifier uniqueness constraint, so conflicting events fail fast before any generated files are written—even if their display `event_name` values intentionally match for legacy reasons.
- Since the parser sorts files, domains, and events before visiting them, every validation failure is predictable and repeatable-no ordering surprises in CI or on different machines.
- `dart run analytics_gen:generate --plan` prints the parsed tracking plan (domains, events, parameters, and fingerprint) so you can inspect instrumentation without writing any generated files.

## CLI Commands

```bash
# Generate code only (default)
dart run analytics_gen:generate

# Generate code + documentation
dart run analytics_gen:generate --docs

# Generate everything
dart run analytics_gen:generate --docs --exports

# Docs only
dart run analytics_gen:generate --docs --no-code

# Exports only
dart run analytics_gen:generate --exports --no-code

# Watch mode (auto-regenerate on changes)
dart run analytics_gen:generate --watch

# Quiet mode (no generator logs, only summary)
dart run analytics_gen:generate --no-verbose

# Validate YAML only (no files written)
dart run analytics_gen:generate --validate-only

# Print the parsed tracking plan (no files written)
dart run analytics_gen:generate --plan
```

## Generated Files

### Code Structure
```
lib/src/analytics/generated/
├── analytics.dart              # Singleton with all mixins
├── generated_events.dart       # Barrel file
└── events/
    ├── auth_events.dart       # AnalyticsAuth mixin
    ├── screen_events.dart     # AnalyticsScreen mixin
    └── purchase_events.dart   # AnalyticsPurchase mixin
```

### Documentation & Exports (Optional)
- **Docs**: `docs/analytics_events.md`
- **CSV**: `assets/generated/analytics_events.csv`
- **JSON**: `assets/generated/analytics_events.json`
- **SQL**: `assets/generated/create_database.sql`
- **SQLite**: `assets/generated/analytics_events.db`

Docs screenshot (Markdown excerpt from the example project):

```markdown
| Event | Description | Status | Parameters |
|-------|-------------|--------|------------|
| auth: login | User logs in to the application | **Deprecated** -> `auth.login_v2` | `method` (string): Login method (email, google, apple) |
| auth: logout | User logs out | Active | - |
```

### Deterministic Metadata
Docs, JSON, and SQL exports embed a fingerprint derived from your YAML tracking plan (for example `Fingerprint: \`-6973fa48b7dfcee0\`` in docs and `"fingerprint": "-6973fa48b7dfcee0"` inside JSON metadata). Because timestamps are no longer written, re-running the generator without plan changes produces byte-identical artifacts across machines.
Repeated runs reuse the same fingerprint and totals, so docs/JSON/SQL files stay byte-for-byte identical even when generated at different times.

## Analytics Providers

### Mock Service (Testing)

Mock service now surfaces typed `RecordedAnalyticsEvent` snapshots through `records`, while the map-based helpers (`getEventsByName`) remain for legacy checks.

```dart
final mockService = MockAnalyticsService(verbose: true);
Analytics.initialize(mockService);

// Verify in tests
expect(mockService.totalEvents, equals(1));
expect(
  mockService.records.where((event) => event.name == 'login'),
  hasLength(1),
);

// Typed snapshots make structured assertions effortless.
final record = mockService.records.single;
expect(record.parameters, containsPair('method', 'email'));

// Legacy map view still mirrors the recorded payload.
final legacy = mockService.getEventsByName('login').first;
expect(legacy['parameters'], containsPair('method', 'email'));
```

### Multi-Provider

```dart
final multiProvider = MultiProviderAnalytics([
  FirebaseAnalyticsService(firebase),
  AmplitudeService(amplitude),
]);
Analytics.initialize(multiProvider);
```

MultiProvider analytics keeps every provider running even if one throws. Supply optional callbacks to log the failure and record metrics:

```dart
final multiProvider = MultiProviderAnalytics(
  [
    FirebaseAnalyticsService(firebase),
    AmplitudeService(amplitude),
  ],
  onError: (error, stackTrace) {
    logger.error('Analytics provider failed', error, stackTrace);
  },
  onProviderFailure: (failure) {
    telemetry.increment('analytics_provider_failure', {
      'provider': failure.providerName,
      'event': failure.eventName,
    });
  },
);
```

`onProviderFailure` receives a `MultiProviderAnalyticsFailure` with the failing provider, event name, parameters, error, and stack trace so you can build observability around lost events.

### Provider Filters (Selective forwarding)

You can optionally control which providers receive each event by passing `providerFilters` into `MultiProviderAnalytics`. Filters are predicates of the event name and parameters; returning `false` prevents the provider from receiving that event.

```dart
final filtered = MultiProviderAnalytics([
  firebase,
  amplitude,
], providerFilters: {
  firebase: (name, params) => name.startsWith('screen'),
  amplitude: (name, params) => true, // receives everything
});

filtered.logEvent(name: 'screen_view'); // sent to firebase + amplitude
filtered.logEvent(name: 'auth_login');   // only sent to amplitude
```

### Custom Provider

```dart
class FirebaseAnalyticsService implements IAnalytics {
  final FirebaseAnalytics _firebase;

  FirebaseAnalyticsService(this._firebase);

  @override
  void logEvent({
    required String name,
    AnalyticsParams? parameters,
  }) {
    _firebase.logEvent(name: name, parameters: parameters);
  }
}

### Provider-specific capabilities

Many SDKs expose richer APIs (user properties, timed/timed-out events, push-token registration, revenue helpers). Use capabilities to surface them without polluting the generated mixins with provider-specific types:

1. **Define a capability type + key**

```dart
final class UserPropertiesCapability implements AnalyticsCapability {
  void setUserProperty(String name, String value);
}

const userPropertiesKey = CapabilityKey<UserPropertiesCapability>('user_props');
```

2. **Expose the capability from your provider**

```dart
class FirebaseAnalyticsService implements IAnalytics, AnalyticsCapabilityProvider {
  final CapabilityRegistry _capabilities = CapabilityRegistry();

  FirebaseAnalyticsService(this._firebase) {
    _capabilities.register(userPropertiesKey, _FirebaseUserProps(_firebase));
  }

  @override
  AnalyticsCapabilityResolver get capabilityResolver => _capabilities;

  // ...existing logEvent(...)...
}
```

3. **Consume the capability anywhere in your app**

```dart
final props = Analytics.instance.capability(userPropertiesKey);
props?.setUserProperty('premium_tier', 'gold');
```

Capabilities keep SOLID boundaries intact: generated code still speaks in terms of plain `logEvent`, while advanced hooks stay discoverable and type-safe for teams that need them.
```

`AnalyticsParams` is a typedef for `Map<String, Object?>`. In practice:

- Keys are always `String` in snake_case.
- Values should be JSON-serializable (String, num, bool, null, List, Map) or simple objects supported by your analytics SDK.

### Async adapters

Some providers expose `Future` based APIs. We provide `IAsyncAnalytics` and
`AsyncAnalyticsAdapter`, which lets you await delivery for synchronous
providers or adapt sync implementations into async flows.

```dart
final adapter = AsyncAnalyticsAdapter(mockService);
await adapter.logEventAsync(name: 'async_event');
```

### Sync vs Async logging

- The `IAnalytics.logEvent` API is synchronous for ergonomics in UI and business code.
- Your implementation may perform asynchronous work internally (e.g. calling an async SDK), but the generated methods themselves do not return a `Future`.
- If you need strict delivery guarantees, handle retries and error reporting inside your `IAnalytics` implementation.

## Deterministic Output

`analytics_gen` sorts YAML files, domains, and events before emitting code, docs, or exports. Running `dart run analytics_gen:generate` on different machines produces identical output as long as the input YAML is the same, which keeps pull request diffs and CI artifacts predictable.

## Testing

Unit tests should initialize `Analytics` with `MockAnalyticsService` (or other adapters) and assert that generated methods call into providers correctly. Add `dart run analytics_gen:generate --validate-only` to CI to fail early on plan errors and invalid YAML.

```dart
void main() {
  group('Analytics', () {
    late MockAnalyticsService analytics;

    setUp(() {
      analytics = MockAnalyticsService();
      Analytics.initialize(analytics);
    });

    test('logs login event', () {
      Analytics.instance.logAuthLogin(method: 'email');

      expect(analytics.totalEvents, equals(1));
      final event = analytics.events.first;
      expect(event['name'], equals('auth: login'));
      expect(event['parameters'], containsPair('method', 'email'));
    });
  });
}
```

## Coverage

[![](https://codecov.io/gh/yelmuratoff/analytics_gen/branch/main/graphs/sunburst.svg)](https://codecov.io/gh/yelmuratoff/analytics_gen/branch/main)

## Example

See [`example/`](example/) for a complete working project.

Run the example:

```bash
cd example
dart pub get
dart run analytics_gen:generate --docs --exports
dart run lib/main.dart
```

## Contributing

Contributions welcome! Please open issues for bugs or feature requests. To contribute:

- Fork the repo and open a PR with targeted changes
- Add unit tests for all new features and validations
- Run `dart analyze` and `dart test` before submitting

## License

Licensed under the Apache License, Version 2.0. See [`LICENSE`](LICENSE) for details.

## FAQ

- **Why YAML instead of defining events directly in Dart?**  
   YAML keeps the tracking plan tooling‑agnostic: product and analytics teams can read and edit it, and you can export the same source of truth to code, docs, and data formats.

- **Can I migrate existing events?** 
   Yes. Start by describing your current events in YAML, generate Dart code, then gradually replace existing manual `logEvent` calls with the generated methods.

- **Does this lock me into a single analytics provider?** 
   No. You implement `IAnalytics` adapters for each provider and can use `MultiProviderAnalytics` to send the same event to several backends.

- **Is this safe to commit to source control?** 
   Yes. The YAML definitions and generated code are designed to be code‑review friendly and should live in your repo alongside application code.
