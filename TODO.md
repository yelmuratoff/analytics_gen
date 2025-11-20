# TODO – `analytics_gen`

## Active Work Items

- [ ] **Linting & Code Quality**
  - Enable `sort_constructors_first` in `analysis_options.yaml`
  - Enable `public_member_api_docs` in `analysis_options.yaml` and fix violations
- [ ] **Documentation & Reliability**
  - Clarify `BatchingAnalytics.flush()` exception behavior in DartDocs

## Refactoring & Improvements (Priority)

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
