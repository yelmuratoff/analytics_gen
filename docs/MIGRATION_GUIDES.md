# Migration Guides

Instrumentation rarely starts from a clean slate. This guide walks through migrating existing analytics stacks to `analytics_gen` while keeping downstream dashboards stable. Each section covers a common provider (Firebase Analytics manual strings, Amplitude, Mixpanel) and calls out mapping strategies, validation tips, and rollout sequencing.

## Shared Migration Checklist

1. **Inventory current events** - export the list of event names + parameters from your existing provider. Include descriptions, allowed values, and any downstream dependency (dashboards, alerts, contractual SLAs).
2. **Define YAML domains** - group events by ownership (auth, screen, purchase) and create `events/<domain>.yaml` files. Use `description`, `parameters`, `deprecated`, and `replacement` metadata to capture the current behavior.
3. **Configure naming strategy** - update `analytics_gen.yaml` with `identifier_template`, `domain_aliases`, and parameter overrides so the generated identifiers match your provider expectations.
4. **Generate + review artifacts** - run `dart run analytics_gen:generate --docs --exports` and inspect generated Dart/doc/export diffs just like production code.
5. **Wire runtime providers** - implement `IAnalytics` (or wrap the SDK you already use) and initialize the generated `Analytics` singleton in your app bootstrap.
6. **Roll out gradually** - release instrumentation file-by-file or screen-by-screen. Keep deprecated events emitting until stakeholders confirm the new events are live.

## Firebase Analytics (manual `logEvent` strings)

Firebase allows arbitrary event names and parameter maps, so migrations are usually about consistency:

1. **Normalize identifiers** - map every historical `logEvent('foo_bar')` call into YAML entries. Use `customEventName` when you must keep the exact Firebase string, and set `identifier` to the new canonical name so the generated code stays idiomatic.
2. **Parameter metadata** - define `type`, `description`, `allowed_values`, and per-parameter `identifier`/`param_name` pairs. Firebase dashboards often rely on snake_case keys; keep them via `param_name` while the generated Dart uses camelCase.
3. **Deprecations** - for legacy events you intend to replace, set `deprecated: true` plus `replacement`. The generator emits `@Deprecated` annotations so call sites are easy to find.
4. **Runtime provider** - if you already wrap `FirebaseAnalytics`, implement `IAnalytics` by delegating to `logEvent` with the generated `name` + `parameters`. You can stack `MultiProviderAnalytics` or `BatchingAnalytics` as needed.
5. **Cut-over** - replace manual `logEvent` calls with generated mixins domain-by-domain. Use CI to ensure developers run `analytics_gen:generate` so Firebase stays in sync with YAML.

## Amplitude

Amplitude events typically include descriptive names (`"User Signed Up"`) and a mix of super properties + event props.

1. **Event naming** - set `customEventName` to the human-friendly Amplitude strings and keep identifiers snake_case (`auth.signup_completed`). This preserves your Amplitude taxonomy while keeping Dart ergonomic.
2. **Property mapping** - document every property under `parameters` with `description`, `type`, and allowed values. When a property is optional, mark it as nullable (`string?`).
3. **Super properties / user properties** - expose provider-specific behavior through capabilities (e.g., `UserPropertiesCapability`) rather than custom mixin code. The controller or service layer can request the capability when needed.
4. **QA** - run Amplitude's "event stream" alongside the generated `MockAnalyticsService` during staging to ensure required properties are present before shipping.

## Mixpanel

Mixpanel projects often have strict property schemas and roll-up dashboards.

1. **Flatten tokens** - Mixpanel likes `PascalCase` or `snake_case` keys; configure `param_name` overrides to keep compatibility while letting the generated Dart use idiomatic names.
2. **Batching** - Mixpanel benefits from batching on mobile. Use `BatchingAnalytics` + `AsyncAnalyticsAdapter` so UI code stays synchronous while uploads happen in the background.
3. **Rollout strategy** - ship the generated mixins in parallel with legacy helpers. Validate using Mixpanel's live view, then delete the legacy helper once dashboards confirm parity.
4. **Exports** - hand the generated CSV/JSON exports (`assets/generated/`) to analysts so they can diff against Mixpanel's official plan.

## Verification Tips

- Add a dedicated integration test that wires `MockAnalyticsService` and asserts that each domain action emits the expected event names/parameters.
- Keep `docs/analytics_events.md` and exports committed so reviewers can spot accidental regressions.
- Use the new Flutter example (`example/`) as a sandbox for teaching developers how to depend on generated mixins through controllers instead of calling `Analytics.instance` everywhere.

Need another provider or deeper steps? Open a doc issue with the target SDK + quirks and we will extend this guide.
