# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]
- Add a PR template that links to the Code Review checklist so contributors must
  explicitly confirm regeneration + docs/exports review before requesting feedback.
- Documented why `IAnalytics.logEvent` stays synchronous and added queueing +
  `AsyncAnalyticsAdapter` examples/tests so contributors know how to await heavy
  providers without changing the base interface.
- Flexible naming strategy block with per-event/parameter overrides:
  - `analytics_gen.naming` now controls snake_case enforcement, default event-name/identifier templates, and domain aliases so legacy tracking plans can migrate progressively.
  - Events accept an optional `identifier` that keeps uniqueness independent of the provider-facing `event_name`.
  - Parameters gained `identifier` (for generated Dart APIs) and `param_name` (for the wire payload). Code generation, docs, and exports respect the new fields and continue validating collisions after camelCase normalization.
  - CSV/JSON/SQL/SQLite exports, docs, the CLI plan printer, and runtime uniqueness checks all use the configured naming strategy so watchdogs stay consistent across layers.
- README onboarding refresh with a top-level checklist, step-by-step walkthrough (describe YAML → configure → generate → use → review), and a quick reference for common validation errors to speed up junior onboarding.

## [0.1.6] - 2025-11-17
- Add `include_event_description` config option to optionally include an
  event's `description` property inside the emitted `logger.logEvent`
   parameters map. This flag defaults to `false` to preserve existing
   behavior; enable it via `analytics_gen.yaml` (key: `include_event_description`).
   - The code generator now inserts a `'description'` key for events that
     have a non-empty description when the flag is enabled.
   - The example config and `README.md` were updated to document this flag.
   - Unit tests assert that descriptions are properly included when enabled
     and omitted otherwise.
- Support interpolated placeholders in custom `event_name` strings
  - You can now include parameter placeholders in `event_name` using
    `{parameter_name}` and the code generator will replace them with
    Dart string interpolation in generated methods (for example,
    `"Screen: {screen_name}"` → `"Screen: ${screenName}"`).
  - The raw `event_name` still appears unchanged in docs/exports so
    metadata remains stable across teams and exports.
  - If a placeholder doesn't match a parameter, it is preserved as-is
    (no silent mutations), so designs and engineers can detect typos
    or handle advanced use cases explicitly.

## [0.1.5] - 2025-11-16
- The entire package is 100% tested.
- Github Actions have been added for code review and testing.
- Improved documentation with usage examples.

## [0.1.4] - 2025-11-15
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

## [0.1.3] - 2025-11-14
- Fix badge issues

## [0.1.2] - 2025-11-14
- Refactor string interpolation and formatting in code generation

## [0.1.1] - 2025-11-13
- Some minor updates and fixes.

## [0.1.0] - 2025-11-13
- Some minor updates and fixes.

## [0.0.1] - 2025-11-13
- Initial release of `analytics_gen` package.
