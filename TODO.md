# TODO – `analytics_gen`

## Active Work Items

## Refactoring & Improvements (Priority)

## Improvements & Refactoring
- [x] **Better YAML Error Reporting**: Refactor `YamlParser` to use `loadYamlNode` instead of `loadYaml`.
    - [x] Implement `SourceSpan` usage to point to exact line/column of errors.
    - [x] Update `AnalyticsParseException` to support `SourceSpan`.
- [x] **Event Name Validation**: Enforce stricter validation for event names to prevent high cardinality issues (interpolation check) directly in the parser.
- [x] **Test Coverage**:
    - [x] Add tests for malformed YAML with expected line/column errors.
    - [x] Verify `strict_event_names` logic.

## Documentation
- [x] Update `CHANGELOG.md`.
- [x] Update `README.md` with info about strict mode.

- [x] **Dart 3 Features**
  - Refactor `AnalyticsException` hierarchy to use `sealed class` for exhaustive error handling.
  - Ensure all models are `final` or `sealed`.

- [x] **Validator Separation**
  - Extract validation logic from `YamlParser` into a dedicated `SchemaValidator` class.
  - Allow for different validation strategies (strict vs lenient).
  - Unit tests for the new validator.

- [x] **Structured Logging**
  - Replace `void Function(String)` callback with a structured logging interface.
  - Improve debuggability for CI/CD pipelines.

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
