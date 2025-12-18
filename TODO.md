# TODO: Technical Debt and Improvements

## Critical Fixes (P0/P1)

- [x] **CI Recovery**: Fix `dart analyze --fatal-infos` failure. Exclude `example/` from analysis in `analysis_options.yaml`.
- [x] **Documentation Sync**: Bring README, ONBOARDING, and TROUBLESHOOTING in sync with reality:
    - [x] `README.md`: Fix `inputs.events` (globs not supported) and `outputs.path` (should be `outputs.dart`).
    - [x] `ONBOARDING.md`: Remove duplicate `targets:` block (checked: none found).
    - [x] `TROUBLESHOOTING.md`: Fix `shared_parameter_paths` → `shared_parameters` (checked: already fixed).
- [x] **Code Generation Vulnerabilities**:
    - [x] **String Escaping**: Escape `"` and `$` in `event_name` during generation.
    - [x] **Regex Escaping**: Handle `'` in regex patterns used in `RegExp(r'''...''')` literals.
    - [x] **Multiline Descriptions**: Split `description` by `\n` in `DocumentationRenderer`.
- [x] **Schema Evolution**: Fix JSON key mismatch: `'nullable'` → `'is_nullable'` in `schema_comparator.dart:284`.
- [x] **Web Protection**: Guard `dart:io` usages in `ConsoleLogger` and `MultiProviderAnalytics`.

## Technical Debt & Refactoring (P2)

- [x] **MultiProviderAnalytics**: Fix discrepancy between doc ("wraps in microtasks") and implementation (direct calls in sync `logEvent`).
- [x] **Export Cleanup**: Extend stale file cleanup to cover all 6 generated CSV files in `export_generator.dart`.
- [x] **Orphaned Doc Comment**: Remove `/// Parses a list of parameters from a YAML map.` in `analytics_parameter.dart:88`.

## Features / Improvements

- [ ] **Glob Support**: Consider adding real glob support to `EventLoader` to match documentation.
