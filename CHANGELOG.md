# Changelog

All notable changes to this project will be documented in this file.

## [2.3.0]

### Behaviour changes

Most of these turn a silent mistake into an error. Check them before upgrading:

- An unknown `naming.casing` value, such as `titleCase`, now stops generation and lists the accepted values. Before, it silently fell back to `snake_case`.
- A parameter written as `name:` with no shared parameter of that name now fails to parse. Before, it generated `required null name`, which did not compile.
- A `regex` that does not compile, a length rule (`min_length`, `max_length`, `regex`) on a non-string type, and a range rule (`min`, `max`) on a non-numeric type now fail to parse. Before, they produced code that did not compile or threw in the app.
- `audit` and `studio_export` reject generation flags such as `--watch` or `--docs`. Before, they accepted and ignored them.
- When `sqlite3` is installed but cannot build the database, generation fails with its error. Before, it reported success and left an empty database.
- The SQL and SQLite exports store `source_path` relative to the project root (`events/auth.yaml`) instead of an absolute path.
- `BatchingAnalytics` and `MultiProviderAnalytics` write failures that have no callback to the console through a `ConsoleLogger`. Pass `logger` to send them elsewhere. In debug builds, a failed flush no longer throws an `AssertionError` in place of the delegate's error.
- Generated context files with a `regex` switch from `r'...'` to `r'''...'''`, the form events already use.

### Features

- Unknown fields in events, parameters and shared parameter files, such as a misspelled `paramters:` or `allowed_value:`, log a warning with the file, line and column. Generation continues.
- `BatchingAnalytics` takes an optional `maxQueueSize` that drops the oldest events while the provider is unreachable, and a `logger`. Every dropped event, including one logged after `dispose()`, goes to `onEventDropped`.
- A shared parameter that sets `param_name` can be referenced by its key in the shared file as well as by that name, matching the Studio.
- `audit` and `studio_export` have their own `--help` and options.

### Fixes

#### Generated code

- Quotes, `$`, backslashes and line breaks in YAML values no longer break the generated Dart: enum values, wire names from `param_name`, context names, `replacement`, multi-line descriptions and regex patterns are escaped.
- Allowed values that differ only in case or separators (`Email`, `email`) report a collision instead of generating two identical enum constants.
- Dual-write calls compile when both parameters are generated enums, convert the value by name, and fall back to logging the target event when the types cannot match, for example a nullable value feeding a required parameter. Arguments are passed by identifier, not by wire name.
- Interpolated event names use the parameter's identifier, so `identifier:` overrides no longer produce undefined variables.
- Nullable enum and `dart_type` parameters no longer generate a `?.` that the analyzer reports as a warning.

#### Parsing and errors

- A field with the wrong type (`description: 42`, `min: "1"`) is reported by name at the value, in event, context and shared parameter files alike. In context and shared files it used to crash with a raw `TypeError`.
- Every located error names its file (`line 3, column 18 of events/auth.yaml`), and a YAML syntax error is reported once instead of twice.
- Mistyped `naming` fields, a `naming` value that is not a map, a config file with only comments, and a config file whose root is a list are reported clearly.
- With `--verbose`, a stack trace is printed only for unexpected failures, not for mistakes in the tracking plan, config or command line.
- The generated YAML templates load again: `event_name_template` is quoted and the regex example no longer uses an invalid escape.

#### CLI and exports

- Watch mode keeps running when a regeneration fails.
- `audit` and the Studio export read the tracking plan the same way generation does, including shared parameters, contexts and glob event paths.
- The dead event report runs `git blame` in the events file's repository, so it shows last-modified details regardless of the current directory.
- The SQLite export quotes the script path, so it works in directories with spaces.
- The schema evolution check treats type aliases (`bool`, `boolean`) as the same type, reports `dart_type` changes and narrowed `allowed_values` as breaking, and reports widened `allowed_values` as non-breaking.
- The Markdown docs link their table of contents to the real heading anchors.
- The Studio export warns about each malformed YAML file it skips and no longer rewrites an unchanged project file.

#### Runtime services

- `BatchingAnalytics.dispose()` delivers events that a failed automatic flush put back in the queue, instead of throwing and losing them.
- A provider filter that throws in `MultiProviderAnalytics`, or a provider that throws before returning a future, is reported through `onProviderFailure` and no longer stops delivery to the other providers.

#### Studio

- The three parameter editors share one form: changing the type keeps the other fields, and switching selections no longer crashes with "Rendered fewer hooks than expected".
- Renames onto an existing name are rejected, new names follow the configured naming rules, and ZIP export is blocked while validation errors remain.
- Navigation no longer enters undo history or marks the project as unsaved, keyboard shortcuts work with Caps Lock or Shift, settings missing from stored projects are filled with their defaults, YAML import reports every failure, and tree controls have accessible names.

### Deprecations

- `ensureAnalyticsInitialized` is deprecated: the generated `Analytics.instance` performs the check. It will be removed in the next major release.
- `BatchingAnalytics.startFlushForTest` is deprecated in favour of `flush()`.

### Internals

- The format check in CI resolves dependencies first; it had failed on every pull request. The Studio ESLint check runs in CI and `sync.sh`, and `sync.sh` now fails when the type check or Studio tests fail.
- Tests use `fake_async` instead of real waits, and the CLI commands run in process. Line coverage of `lib/` rose from 93.6% to 95.8%.
- Field lists, type aliases, config defaults and the generated-enum rule each live in one place, and a test keeps them in step with `schema/*.json`.
- Unused internal code was removed.

## [2.2.2]

### Fixes

- Widened the `analyzer` constraint to `>=7.7.1 <15.0.0`. Projects on Dart 3.10+ need a newer `analyzer` for `build_runner`, `freezed`, and `drift_dev`, and the previous `^7.7.1` pin blocked their resolution. Projects that stay on `analyzer` 7 resolve as before.

## [2.2.1]

### Features

- Added the `analytics-gen-yaml-schema` package skill for AI agents creating, updating, and validating YAML tracking plans. Install it from an application that depends on `analytics_gen` with `dart run skills@ get -p analytics_gen -s analytics-gen-yaml-schema`.

## [2.2.0]

### Features

- **Studio remembers your project file** — after a reload the Studio reconnects to the last opened `analytics-studio.json` (Chrome/Edge, via the File System Access API) and remembers the file name on every browser, so you no longer re-open it each session. `Save` writes straight back to the same file; data is auto-saved locally regardless.
- **Project identity & content revision for CI/CD** — saved and generated `analytics-studio.json` now carries a `meta` block with a stable `projectId`, an optional `name`, and a content `revision` hash. The revision is deterministic and timestamp-free, so CI can compare project files across commits to detect analytics changes. The Dart `studio` target emits the same `meta` and preserves `projectId` across regenerations.
- **Customizable / unique export names** — set a project name (drives both the `.json` and ZIP file names) and optionally append the content-revision hash for unique CI-artifact names, via the new "Project…" dialog (which also shows the project ID and revision).
- **External-change detection** — when `analytics-studio.json` changes on disk (an external edit, a `git pull`, a CI regeneration), the Studio offers to reload it instead of silently diverging (Chrome/Edge).

### Internals

- Shared cross-language `revision` hash (cyrb53 over canonical, key-sorted JSON) implemented in both the Studio (`project-meta.ts`) and the Dart generator (`project_revision.dart`), locked by a parity test so a studio-saved and a CI-generated file agree for identical content.

## [2.1.0]

### Features

- **Studio export as a first-class generation target** — added `targets.studio` (with `outputs.studio` path) to `analytics_gen.yaml`. The Studio project file is now produced by the main pipeline alongside Dart code, docs, and exports.
- **`--studio` CLI flag** for `dart run analytics_gen:generate`. CLI flags follow the same precedence as `--docs` / `--exports`: explicit flag wins over config, with `--no-studio` to disable.
- **Flat aliases** `generate_studio` and `studio_path` are accepted at the root of the config for parity with other targets.

### Fixes

- Studio now normalizes events when loading a project file — events without a `parameters` block (allowed by schema) no longer crash the import. YAML and JSON import paths share the same normalization logic.

### Internals

- Extracted studio export logic into `StudioGenerator` so the standalone `analytics_gen:studio_export` binary and the main pipeline use the same zero-knowledge YAML reader.

## [2.0.0]

### Features

- **Analytics Gen Studio** — web-based visual editor for analytics configuration, events, shared parameters, and contexts with real-time YAML preview.
- **Schema as Single Source of Truth** — JSON schemas in `schema/` now drive everything: Studio UI, TypeScript types, YAML templates, and documentation.
- **Schema-driven generation** — YAML templates, schema reference docs, and Studio TypeScript types are all auto-generated from JSON schemas.
- **Studio features**: search/filter in event tree, keyboard shortcuts (Ctrl+S/O), notifications, compact array inputs, validation error badges on tabs, confirm dialogs for all deletions, auto-fill context name from filename.

### Architecture

- Studio renders all forms dynamically from JSON schemas — no hardcoded data.
- TypeScript types auto-generated from schemas.
- YAML templates and schema reference docs auto-generated from schemas.
- All YAML field names centralized via constants — no raw string literals in parsers.

## [1.1.0]

### Features

- Added `boolean` as an alias for `bool` type across type mapping, parsing, and documentation generation.
- Added automatic tracking creation date injection via a new ledger file and `meta.auto_tracking_creation_date` config option.
  - When enabled, the generator maintains a `.analytics_tracking.json` ledger file that records an ISO 8601 timestamp (`yyyy-MM-ddTHH:mm:ss`) when each event is first seen.
  - The `tracking_creation_date` value is automatically injected into each event's `meta` field during generation.
  - Existing entries are never overwritten — the ledger preserves the original creation timestamp.
  - The ledger file is placed next to `analytics_gen.yaml` and should be committed to version control.
- Added `meta.include_meta_in_parameters` config option to include event meta fields in the generated `eventParameters` map sent to analytics providers (e.g. Amplitude, Mixpanel). Default: `false`.

## [1.0.8]

### Features

- Added `dartReservedWords` to `StringUtil` to prevent enum member name collisions with Dart keywords.

## [1.0.7]

### Features

- Export generated events from the analytics class renderer for easier access

## [1.0.6]

### Bug Fixes

- Fixed `NamingStrategy._toTitleCase` stripping structural punctuation (e.g. `:`) from `event_name_template`. Previously, using `casing: title_case` with a template like `"{domain}: {event}"` produced `"Chat Under Dev Sheet Shown"` instead of `"Chat: Under Dev Sheet Shown"`. Only `_` and `-` are now treated as word boundaries.

## [1.0.5]

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
