# TODO – `analytics_gen`

## Active Work Items

- [ ] **Extensible Metadata Support (Custom Fields)**
  - **Goal**: Allow users to define custom fields like `owner`, `is_pii`, `jira_ticket` in YAML under a `meta` key.
  - **Implementation**: Update `YamlParser` to read `meta`. Update models, docs, and exports to include it.
  - **Benefit**: Solves ownership and PII flagging elegantly without hardcoding fields.

- [ ] **User Properties & Context Generation**
  - **Goal**: Generate type-safe setters for stateful properties (e.g., `setUserRole`) from YAML.
  - **Implementation**: Support `user_properties.yaml`, generate mixins that delegate to `AnalyticsCapability`.
  - **Benefit**: Type-safety for state tracking, not just event logging.

## Notes
- Tests must also keep covering the export cleanup + analytics plan metadata; broaden them once the new naming strategy and capability adapters land.
- README updates should mention the runtime plan constant, refined watch/export behaviors, and the newly added naming/capability customization knobs.
