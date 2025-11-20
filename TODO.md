# TODO – `analytics_gen`

## Active Work Items

### High Priority

- [x] **Enhanced CSV Export for Analytics** (Analyst-Friendly)
  - [x] Add separate parameters CSV with parameter-per-row structure for filtering
  - [x] Add metadata CSV with meta-per-row structure for easy querying
  - [x] Create events-parameters relationship table for SQL-like joins
  - [x] Improve readability with proper escaping and formatting
  - [x] Add export documentation for analysts

### Medium Priority

- [x] **Parameter Validation DSL** (Future enhancement)
  - [x] Add validation rules support in YAML (regex, min_length, max_length, range)
  - [x] Generate runtime validation code for parameters
  - [x] Update docs with validation examples
- [x] Add ignore of lints to generated dart files, datetime of last generation

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

- [ ] **Export Format Extensions**
  - Add Protobuf schema generator for type-safe integrations
  - Add Parquet export for big data pipelines
  - Add Prometheus metrics format for real-time monitoring

## Notes
- Tests must also keep covering the export cleanup + analytics plan metadata; broaden them once the new naming strategy and capability adapters land.
- README updates should mention the runtime plan constant, refined watch/export behaviors, and the newly added naming/capability customization knobs.
