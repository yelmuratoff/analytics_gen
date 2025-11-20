# TODO – `analytics_gen`

## Active Work Items

### Medium Priority

- [ ] **Parameter Validation DSL** (Future enhancement)
  - Add validation rules support in YAML (regex, min_length, max_length, range)
  - Generate runtime validation code for parameters
  - Update docs with validation examples

- [ ] **Export Format Extensions**
  - Add Protobuf schema generator for type-safe integrations
  - Add Parquet export for big data pipelines
  - Add Prometheus metrics format for real-time monitoring

- [ ] **Plugin System**
  - Design plugin interface for custom generators/validators
  - Add plugin discovery mechanism
  - Document plugin development guide

### Low Priority

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

## Notes
- Tests must also keep covering the export cleanup + analytics plan metadata; broaden them once the new naming strategy and capability adapters land.
- README updates should mention the runtime plan constant, refined watch/export behaviors, and the newly added naming/capability customization knobs.
