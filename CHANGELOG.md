# Changelog

All notable changes to this project will be documented in this file.

## [0.2.1] - 2025-11-21

### Breaking Changes
- **Configuration Structure Update**: The `analytics_gen.yaml` file has been completely restructured into logical groups (`inputs`, `outputs`, `targets`, `rules`) to improve readability and organization.
  - **Migration Guide**:
    ```yaml
    # Old (v0.2.0)
    analytics_gen:
      events_path: events
      output_path: lib/src/analytics
      docs_path: docs/analytics.md
      generate_docs: true
      strict_event_names: true
      event_parameters_path: events/shared.yaml

    # New (v0.2.1)
    analytics_gen:
      inputs:
        events: events
        shared_parameters:
          - events/shared.yaml
      outputs:
        dart: lib/src/analytics
        docs: docs/analytics.md
      targets:
        docs: true
      rules:
        strict_event_names: true
    ```
  - **Note**: The old flat structure is deprecated but may still work for some fields during a transition period, though migration is strongly recommended. `event_parameters_path` is strictly removed in favor of `inputs.shared_parameters`.

### Highlights
- Improved error reporting, validation, and generated code ergonomics.
- Better CSV/exports, optional PII scrubbing, and safer enum generation for parameter values.
- Added telemetry hooks and testing helpers (e.g., `Analytics.reset()`).

### Documentation & DX
- Clarified `BatchingAnalytics.flush()` behavior and updated README guidance.
- Added CI example for plan validation in `doc/VALIDATION.md`.

### Key Additions
- **Shared Event Parameters**: Support for centrally defined parameters via `shared_parameters`.
  - Reuse parameters across events by referencing them (or leaving value as `null`).
  - Enforce consistency with `enforce_centrally_defined_parameters`.
  - Prevent duplicates with `prevent_event_parameter_duplicates`.
- Enhanced CSV export (multiple files, better escaping).
- Parameter validation DSL: `regex`, `min_length`, `max_length`, `min`, `max` with runtime checks.
- PII scrubbing support (`PiiRenderer` + `Analytics.sanitizeParams`).
- Enum generation for parameters with `allowed_values`.

### Internal Improvements
- `BaseRenderer` to share common rendering logic across generators.
- Generation telemetry (`GenerationTelemetry` + implementations) integrated into `CodeGenerator`.
- Validator separation: `SchemaValidator` extracted from `YamlParser` with tests.
- `YamlParser` refactored to use `loadYamlNode` and enforces strict event-name rules.

### Misc
- Added `ignore_for_file` lints and generation timestamp to generated files.
- `Analytics.reset()` for testing and hot-restart scenarios.

## [0.2.0] - 2025-11-20
- **Updates**:
  - Optimized generator performance with parallel processing and smart I/O.
  - Stable API supporting both Dependency Injection and Singleton patterns.
- **Major Features**:
  - **Extensible Metadata**: Support for arbitrary key-value pairs (`meta`) in YAML, propagated to code and exports.
  - **Batching & Async**: Added `BatchingAnalytics` for buffering events and `AsyncAnalyticsAdapter` for heavy providers.
  - **Flexible Naming**: Configurable naming strategies for domains, events, and parameters.
  - **Strict Mode**: Added `strict_event_names` to prevent high-cardinality anti-patterns.
- **Developer Experience**:
  - **Improved Error Reporting**: Aggregated validation errors for faster debugging.
  - **Performance**: Parallelized generation and incremental file writes.
  - **Documentation**: Added migration guides, scalability benchmarks, and onboarding checklists.
- **Quality Assurance**:
  - Full test coverage (100%).
  - Stricter linting rules and CI guardrails.

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
