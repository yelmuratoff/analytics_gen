# TODO – `analytics_gen`

## Active Work Items

- [x] **Linting & Code Quality**
  - Enable `sort_constructors_first` in `analysis_options.yaml`
  - Enable `public_member_api_docs` in `analysis_options.yaml` and fix violations
- [x] **Documentation & Reliability**
  - Clarify `BatchingAnalytics.flush()` exception behavior in DartDocs

## Refactoring & Improvements (Priority)

- [x] **Dead Letter Queue (DLQ)**
  - Add `onEventDropped` callback to `BatchingAnalytics`.
  - Allow handling events that failed to send after max retries (e.g., save to disk).

- [ ] **PII Scrubbing Support**
  - Add runtime support for handling PII parameters defined in YAML.
  - Consider automatic redaction in debug logs or helper methods.

- [ ] **Generated Tests**
  - Generate a `test/generated_plan_test.dart` file.
  - Verify that all events defined in YAML can be constructed and pass validation.

- [x] **Singleton Reset**
  - Add `Analytics.reset()` method visible for testing to allow clearing the singleton instance.
  - Useful for integration tests and hot restarts.

- [x] **CI/CD Integration Guide**
  - Add GitHub Actions workflow example to documentation.
  - Show how to run `dart run analytics_gen:generate --validate-only` in CI.

- [x] **Strict Event Naming**
  - Make `strict_event_names: true` the default in future versions.
  - Ensure documentation strongly encourages strict mode.

- [x] **Context Operations**
  - Support specific operations for user properties (increment, setOnce, append) in YAML.
  - Generate specific capability methods for these operations.

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
