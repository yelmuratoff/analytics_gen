# Changelog

All notable changes to this project will be documented in this file.

## [1.0.5] - Unreleased
- Added `templates/analytics_gen.yaml` as a reference for all configuration options.
- Added `templates/events.yaml` demonstrating event and parameter definitions.
- Update README to enhance clarity and structure of `analytics_gen` documentation.
- Add onboarding and AI prompt guides to documentation; enhance README with new links.

## [1.0.4]

### Improvements
- Introduced `CapabilityProviderBase` to replace `CapabilityProviderMixin` (deprecated).
- Added `--metrics` flag to track generation performance.
- Added "Dead Event" Audit Enhancement with git commit info.
- Glob Pattern Support: `EventLoader` now supports glob patterns (e.g., `events/**/*.yaml`).
- Improved Fingerprint Sensitivity: covers all event/parameter fields.
- Cross-Platform Robustness: Normalized path handling for Windows/macOS/Linux.
- Added `doc/PERFORMANCE.md`, `doc/TROUBLESHOOTING.md`, `doc/TESTING.md`.

### Bug Fixes
- Fixed data loss bug in `BatchingAnalytics` where queue would stall after failed auto-flush.
- Fixed `ConfigParser` crash when optional fields are explicitly `null`.
- `CapabilityRegistry` now throws `StateError` on duplicate capability keys.
- Added default error logging to `BatchingAnalytics` and `MultiProviderAnalytics`.

## [1.0.3]

### Features
- Added "Dead Event" Audit Command (`dart run analytics_gen:audit`).
- Added `test_matchers` target to generate typed `package:test` matchers.
- Added `dart_type` parameter option to map parameters to existing Dart types.
- Added `imports` configuration for including external types.
- Added configurable event naming strategy (`casing`: `snake_case`, `title_case`, `original`).

### Improvements
- Generated code now uses `const` maps for constant event parameters.
- Removed auto-generated tests in favor of `test_matchers`.

## [1.0.2]

- Enhanced SQL/CSV/JSON export formats with additional metadata.
- Formalized analytics data representation with `AnalyticsParameter` and `AnalyticsDomain` models.
- Conditionally generate Flutter or Dart test imports based on project type.

## [1.0.0]

- Stable release with full documentation and API reference.

## [0.2.1]

### Breaking Changes
- **Configuration restructured** into logical groups (`inputs`, `outputs`, `targets`, `rules`).
  ```yaml
  # Old → New
  events_path → inputs.events
  output_path → outputs.dart
  docs_path → outputs.docs
  event_parameters_path → inputs.shared_parameters
  ```

### Features
- **Shared Event Parameters** via `shared_parameters` config.
- Parameter validation DSL: `regex`, `min_length`, `max_length`, `min`, `max`.
- Enum generation for parameters with `allowed_values`.
- Enhanced CSV export with multiple files and better escaping.
- `Analytics.reset()` for testing and hot-restart scenarios.

## [0.2.0]

### Features
- **Extensible Metadata**: Support for `meta` key-value pairs in YAML.
- **Batching & Async**: Added `BatchingAnalytics` and `AsyncAnalyticsAdapter`.
- **Flexible Naming**: Configurable naming strategies.
- **Strict Mode**: `strict_event_names` to prevent high-cardinality.

### Improvements
- Optimized generator with parallel processing.
- Full test coverage (100%).

## [0.1.6]

- Added `include_event_description` config option.
- Support interpolated placeholders in `event_name` (e.g., `"Screen: {screen_name}"`).

## [0.1.5]

- Full test coverage.
- Added GitHub Actions CI.

## [0.1.4]

### Features
- Added CLI flags: `--validate-only`, `--watch`, `--verbose`, `--plan`.
- `MultiProviderAnalytics` with error isolation and `onProviderFailure` hook.
- Event deprecation lifecycle with `deprecated` + `replacement`.
- `allowed_values` for parameters with runtime validation.
- Deterministic fingerprints in exports (no timestamps).

### Improvements
- Stricter YAML parser with better error messages.
- `RecordedAnalyticsEvent` for typed mock assertions.

## [0.1.3]

- Fix badge issues.

## [0.1.2]

- Refactor string interpolation in code generation.

## [0.1.1]

- Minor updates and fixes.

## [0.1.0]

- Minor updates and fixes.

## [0.0.1]

- Initial release.
