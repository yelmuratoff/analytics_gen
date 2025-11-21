# TODO – `analytics_gen`

## Community Feature Requests

- [x] **Shared Event Parameters** (Issue #123)
  - Add `event_parameters_path` to `AnalyticsConfig` to define a central location for shared parameters.
  - Add `enforce_centrally_defined_parameters` config to restrict ad-hoc parameter definitions.
  - Add `prevent_event_parameter_duplicates` config to encourage reuse.
  - Implement `ParameterResolver` to merge shared parameters into event definitions during parsing.
  - Support referencing shared parameters in YAML (e.g. by name or with `null` value).

- [ ] **Advanced Parameter Validation**
  - Add `regex` property to parameter definitions for validation.
  - Generate runtime validation code in Dart to enforce regex patterns.

- [ ] **Schema Evolution & Migration**
  - Implement breaking change detection (compare current schema vs previous).
  - Add `added_in` and `deprecated_in` version metadata to events/parameters.
  - Support "dual-write" migration strategies (sending old and new events simultaneously).

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
