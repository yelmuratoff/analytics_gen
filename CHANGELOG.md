# Changelog

All notable changes to this project will be documented in this file.

## [0.1.4] - Unreleased
- Library vs CLI logging cleanup: internal generators and parsers now emit logs only when a verbose callback is provided, while the CLI keeps the rich user-friendly output.
- Core models (`AnalyticsParameter`, `AnalyticsEvent`, `AnalyticsDomain`) implement value semantics and have dedicated equality tests.
- YAML parser is much stricter: domains/events/parameters must be maps, errors surface file + key context, and malformed structures throw `FormatException`.
- Public API ergonomics:
  - Added `typedef AnalyticsParams = Map<String, Object?>`.
  - `IAnalytics.logEvent` and generated methods use typed params while remaining synchronous by design.
  - README explains serialization expectations and sync logging rationale.
- Enforced snake_case domain naming and documented expectations so files stay filesystem-safe.
- CLI UX:
  - Added `--validate-only`, `--watch`, `--verbose`, and negatable `--code`/`--docs`/`--exports` flags for flexible runs.
  - `--docs`/`--exports` now respect `analytics_gen.yaml` defaults with `--no-docs`/`--no-exports` overrides.
  - `--help` highlights all new options.
- Generators & exports now include thorough tests (code, docs, JSON, SQL, SQLite) using temp directories.
- `MultiProviderAnalytics` catches provider errors, emits a `MultiProviderAnalyticsFailure` payload, fires an optional `onProviderFailure` hook for logging/metrics, and still calls `onError` so the rest of the providers keep running.
- Documentation expanded with analytics best practices, naming guidance, cardinality tips, and example YAML snippets.
- Internal polish: shared string helpers extracted, `MockAnalyticsService` aligns with `AnalyticsParams`, and CI discipline enforced via `dart analyze`/`dart test`.
- Mock analytics service now exposes immutable `RecordedAnalyticsEvent` snapshots through `records` while keeping the legacy map helpers for compatibility.
- Event deprecation lifecycle: YAML accepts `deprecated` + `replacement`, generators emit `@Deprecated`, and metadata is surfaced in docs/exports.
- Parameters support `allowed_values`, propagated through docs/JSON/SQL/CSV with validation.
- Validation/DX enhancements: `--validate-only` mode verifies the tracking plan without writing files and fails fast on structural issues.
- Docs/JSON/SQL exports embed deterministic fingerprints (no timestamps) so repeated runs stay diff-friendly across machines.
- Docs tables gained a Status column that marks deprecated events (and their replacements) so migrations are visible without leaving the Markdown export.
- Parser now enforces that every analytics event name (custom `event_name` or the default `<domain>: <event>`) is unique across domains so generation fails fast on collisions.
- Added a `--plan` CLI flag that surfaces the tracking plan fingerprint, domain/event counts, and parameter lists without writing files so teams can inspect instrumentation quickly.

## [0.1.3] - 2025-11-15
- Fix badge issues

## [0.1.2] - 2025-11-14
- Refactor string interpolation and formatting in code generation

## [0.1.1] - 2025-11-13
- Some minor updates and fixes.

## [0.1.0] - 2025-11-13
- Some minor updates and fixes.

## [0.0.1] - 2025-11-13
- Initial release of `analytics_gen` package.
