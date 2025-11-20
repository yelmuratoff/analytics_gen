# TODO – `analytics_gen`

## Active Work Items

- [ ] **BatchingAnalytics Resilience**: Implement "Poison Pill" protection.
  - [ ] Add retry counter to queued events.
  - [ ] Drop events that fail to send after N attempts to prevent blocking the queue indefinitely.
- [ ] **Analytics.initialize Safety**: Prevent accidental re-initialization.
  - [ ] Add a check in `Analytics.initialize` to throw or warn if called when `_instance` is already set.
- [x] **Improve Error Reporting**: Collect all validation errors in `YamlParser` and report them at once instead of failing on the first one.
- [x] **Strict Mode for Event Names**: Add configuration to treat string interpolation in event names as a build error (high cardinality protection).
- [x] Refactor `CodeGenerator`: Extract string rendering logic into separate Renderer classes (SRP).
  - [x] Create `EventRenderer` for domain mixins.
  - [x] Create `ContextRenderer` for context capabilities.
  - [x] Create `AnalyticsClassRenderer` for the main singleton.
  - [x] Update `CodeGenerator` to use renderers and handle only file I/O.
  - [x] Add unit tests for renderers.
- [x] Refactor `YamlParser`: Extract parameter parsing logic into `ParameterParser`.
- [x] Refactor `CodeGenerator`: Inject renderers via constructor for better testability.

## Notes
- Tests must also keep covering the export cleanup + analytics plan metadata; broaden them once the new naming strategy and capability adapters land.
- README updates should mention the runtime plan constant, refined watch/export behaviors, and the newly added naming/capability customization knobs.
