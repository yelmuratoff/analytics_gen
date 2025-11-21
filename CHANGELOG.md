# Changelog

All notable changes to this project will be documented in this file.

## [0.2.2] - Unreleased

### Added
- **Enum Generation**:
  - Automatically generates Dart enums for string parameters with `allowed_values`.
  - Enums are named `Analytics{Domain}{Event}{Param}Enum` to ensure uniqueness.
  - Generated methods use these enums for type-safe logging.

### Improved
- **Initialization Error**:
  - Improved the error message when `Analytics.instance` is accessed before initialization to be more actionable.

## [0.2.1] - Unreleased

### Documentation
- Clarified `BatchingAnalytics.flush()` exception behavior: manual flushes throw on failure, while auto-flushes suppress errors and report to `onFlushError`.
- Updated `README.md` with explicit error handling guidance for batching.

### Code Quality
- Enabled `sort_constructors_first` and `public_member_api_docs` lints.
- Fixed all lint warnings across the codebase.
- Improved documentation for public members in `BatchingAnalytics`, `MultiProviderAnalytics`, and core models.

### Added
- **Enhanced CSV Export**:
  - Generates multiple CSV files: `analytics_events.csv`, `analytics_parameters.csv`, `analytics_metadata.csv`, `analytics_event_parameters.csv`.
  - Improved readability with proper escaping and formatting.
  - Added parameter-per-row and meta-per-row structures for easier analysis.
- **Parameter Validation DSL**:
  - Support for validation rules in YAML: `regex`, `min_length`, `max_length`, `min`, `max`.
  - Generates runtime validation code for parameters.
- **Generated Code Improvements**:
  - Added `ignore_for_file` lints to generated Dart files.
  - Added timestamp of last generation to file headers.
- **Better Error Reporting**: Now uses `SourceSpan` to point to the exact line and column in the YAML file where an error occurred.
- **Strict Event Naming**: The parser now throws an error if event names contain interpolation characters (`{}`) to prevent high cardinality issues.
- **BaseRenderer**: Extracted common rendering functionality into a base class to reduce code duplication across renderers
  - Shared methods for file headers, imports, documentation comments, and validation checks
  - `MethodParameter` class for type-safe parameter definitions
  - Improved maintainability and consistency across generators
- **Generation Telemetry**: Added performance tracking and observability for code generation
  - `GenerationTelemetry` abstract class with lifecycle hooks
  - `LoggingTelemetry` implementation for console output
  - `NoOpTelemetry` for production use without overhead
  - Track domain/context processing times and total generation duration
  - Integrated into `CodeGenerator` with automatic metrics collection
- **Capability Discovery**: Enhanced generated Analytics class documentation
  - Auto-generated capability documentation in class comments
  - Lists all available capabilities with usage examples
  - Shows capability keys, types, and method signatures
  - Helps developers discover context property setters
- **Singleton Reset**: Added `Analytics.reset()` method (visible for testing) to clear the singleton instance, facilitating integration tests and hot restarts.
- **CI/CD Documentation**: Added GitHub Actions workflow example to `doc/VALIDATION.md` for automated plan validation.
- **Dead Letter Queue (DLQ)**:
  - Added `onEventDropped` callback to `BatchingAnalytics`.
  - Allows handling events that failed to send after max retries (e.g., save to disk).
- **PII Scrubbing Support**:
  - Added `PiiRenderer` to generate PII redaction logic.
  - Added `Analytics.sanitizeParams` method to redact PII fields defined in YAML.

### Changed
- Refactored `YamlParser` to use `loadYamlNode` internally.

### Refactoring
- **Validator Separation**:
  - Extracted validation logic from `YamlParser` into a dedicated `SchemaValidator` class.
  - Improved separation of concerns and testability.
  - Added comprehensive unit tests for validation logic.
- **Dart 3 Features**:
  - Refactored `AnalyticsException` hierarchy to use `sealed class` for exhaustive error handling.
- **Refactoring**:
  - Moved event name interpolation validation from `EventRenderer` to `YamlParser` and `SchemaValidator`.
  - `YamlParser` now correctly propagates `strictEventNames` configuration to domain parsers.

### Improved
- All renderers now extend `BaseRenderer` for consistent code generation
- Reduced code duplication across `EventRenderer`, `ContextRenderer`, and `AnalyticsClassRenderer`
- Better error messages and validation feedback

### Tests
- Added comprehensive test suite for `BaseRenderer` (23 tests)
- Added full test coverage for `GenerationTelemetry` (7 tests)
- All 199 tests passing with 100% coverage maintained

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
