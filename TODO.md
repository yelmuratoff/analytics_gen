# TODO – `analytics_gen`

## Active Work Items

- [x] **Generator Determinism & Validation**
  - Remove non-deterministic timestamps from generated headers to keep diffs clean
  - Make `allowed_values` type-aware (respect ints/bools/doubles) so runtime validation compares correct types
  - Preserve meta value types when emitting runtime plan (avoid stringifying booleans/nums)
  - Enforce strict event-name handling to prevent high-cardinality interpolated names from shipping by default

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
