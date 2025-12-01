# TODO – `analytics_gen`

## High Priority Improvements (Data Analyst Suggestions)

- [ ] **1. Generate dbt Schema (`schema.yml`)**
  - Problem: Data analysts use dbt for data transformation and manually recreate event descriptions and tests (e.g., accepted values) from `analytics_gen` YAML into dbt YAML.
  - Solution: Add a generator to create `schema.yml` files for dbt.
    - Map events to dbt models/sources.
    - Map event/parameter descriptions to dbt descriptions (auto-documentation for DWH).
    - Map allowed values to dbt tests (`accepted_values`).
    - Map non-nullable parameters to dbt tests (`not_null`).
  - This positions `analytics_gen` as a Single Source of Truth for both mobile app and Data Warehouse schemas.

- [ ] **2. Semantic Validation Formats**
  - Problem: Currently, validating formats like email or UUID requires complex, error-prone regex.
  - Solution: Support a `format` field in parameters to automatically generate regex and checks.
    - Example: `format: email`, `format: uuid`.

- [ ] **3. Data Catalog Integration (AsyncAPI)**
  - Problem: While Markdown docs are good, modern data platforms (DataHub, Amundsen) benefit from machine-readable specifications.
  - Solution: Generate AsyncAPI specifications, an industry standard for event-driven architectures.

## Developer Experience & Safety Improvements

- [ ] **4. PII Guardrails (Auto-hashing/Masking)**
  - Problem: `meta: { pii: true }` is currently just documentation. Developers can still accidentally log raw PII.
  - Solution: Enforce PII handling in generated code.
    - Option A: Generated methods require wrapped types (e.g., `HashedString email` instead of `String email`).
    - Option B: Auto-apply mask/hash logic in the generated method body unless an `allowUnsafe` flag is passed.

- [ ] **5. Generated Test Matchers**
  - Problem: Testing analytics requires brittle mocks: `verify(mock.logEvent('login', {'method': 'email'}))`.
  - Solution: Generate typed Matchers for `package:test`.
    - Usage: `expect(analytics, emitsEvent(AuthEvents.login(method: 'email')))`.
    - Enables true TDD for analytics instrumentation.

- [ ] **6. "Dead Event" Audit Command**
  - Problem: YAML plans grow indefinitely; unused events clutter the codebase and confusion.
  - Solution: Add `dart run analytics_gen:audit` command.
    - Scans the Dart codebase using `analyzer`.
    - Reports generated event methods that have 0 usages.

- [ ] **7. Offline-first Schema Generation (Drift/Isar)**
  - Problem: Apps needing offline event batching currently manually duplicate the YAML schema into local DB definitions.
  - Solution: Generate `@DataClassName` (Drift) or Isar collections directly from `analytics_gen` YAML.

- [ ] **8. Custom Linter (`analytics_gen:lint`)**
  - Problem: In large teams, analytics definitions can become inconsistent (naming, descriptions, deprecated event handling).
  - Solution: Add `dart run analytics_gen:lint` command.
    - Checks naming conventions (e.g., enforce snake_case for event names).
    - Requires meaningful descriptions (> 10 characters).
    - Bans "stop-words" (e.g., "test", "temp", "debug") in event/parameter names for production branches.
    - Ensures `deprecated: true` events have a `replacement` specified.

- [ ] **9. In-App Debug Overlay (`AnalyticsDebugView`)**
  - Problem: Verifying analytics events requires connecting external proxy tools (Charles/Proxyman) or reading messy console logs.
  - Solution: Generate a `AnalyticsDebugView` widget (similar to Alice/Chucker).
    - Lists sent events in real-time within the debug app.
    - Shows parameter values and validation errors.
    - Highlights failed events.

- [ ] **10. Semantic PR Reports (Diff Generator)**
  - Problem: YAML diffs in PRs are hard to read; breaking changes or deletions are easily missed.
  - Solution: Add `dart run analytics_gen:diff --base=main` command.
    - Compares current schema vs. base branch.
    - Generates a Markdown report for PR comments:
      - 🚨 **Breaking Changes** (removed params, changed types).
      - ✨ **New Events**.
      - ⚠️ **Deprecations**.

- [ ] **11. JSON Schema for IDE Autocomplete**
  - Problem: Developers make syntax errors in YAML (typos in keys, missing required fields) and only find out during generation.
  - Solution: Generate `analytics_gen.schema.json`.
    - Configuring this in VS Code/IntelliJ provides real-time autocomplete and validation for the YAML files.

- [ ] **12. CSV/Excel to YAML Import**
  - Problem: Analysts often draft tracking plans in spreadsheets. Manually porting them to YAML is slow and error-prone.
  - Solution: Add `dart run analytics_gen:import_csv <file>` command.
    - Parses a CSV with standard columns (Domain, Event, Param, Type, Description).
    - Generates or updates the corresponding YAML files automatically.

- [ ] **13. Automated Changelog (`ANALYTICS_CHANGELOG.md`)**
  - Problem: Stakeholders ask "What analytics changed in this release?" and dev have to dig through git history.
  - Solution: Auto-append to a `ANALYTICS_CHANGELOG.md` file during generation.
    - Lists new events, changed parameters, and deprecations grouped by date/version.

- [ ] **14. Type-Safe Dart Enum Mapping**
  - Problem: Passing Dart enums to analytics requires `.name` everywhere (`analytics.log(role: user.role.name)`). If the enum changes, analytics breaks silently.
  - Solution: Support `dart_type` in YAML parameter definition.
    - The generated method accepts the Dart enum type directly.
    - The generator handles the serialization (e.g., `.name` or a custom mapper) internally.

## Low Priority Improvements

- [ ] **Cloud Integration**
  - BigQuery schema sync
  - Snowflake schema sync
  - Data warehouse integration guide

- [ ] **Visual Plan Editor** (Long-term)
  - Web UI for non-technical stakeholders
  - YAML editor with validation
  - Live preview of generated code

- [ ] **A/B Testing Support**
  - Variant tracking in YAML
  - Conditional event logging
  - Experiment metadata

- [ ] **Export Format Extensions**
  - Add Protobuf schema generator for type-safe integrations
  - Add Parquet export for big data pipelines
  - Add Prometheus metrics format for real-time monitoring

## Notes
- Tests must also keep covering the export cleanup + analytics plan metadata; broaden them once the new naming strategy and capability adapters land.
- README updates should mention the runtime plan constant, refined watch/export behaviors, and the newly added naming/capability customization knobs.