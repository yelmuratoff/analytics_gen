# TODO – `analytics_gen`

## Active Work Items

### Flexible naming + uniqueness customization
- [ ] Audit current snake_case enforcement and uniqueness constraints across `YamlParser`, `EventNaming`, README, and tests to understand the coupling points and downstream effects of loosening the rules.
- [ ] Design a `NamingStrategy` (config + value object) that lets users opt into legacy naming (e.g., relaxed validation, domain aliases, per-event `identifier`, overridable `<domain>: <event>` template) while keeping the existing behavior as the default.
- [ ] Extend the YAML schema + parser to honor the new strategy (`analytics_gen.naming` block, optional `identifier`/`param_name` overrides) without breaking generated Dart identifiers; surface precise errors when overrides conflict after normalization.
- [ ] Update unique event-name resolution to rely on the configured template/override rules, and add regression tests covering mixed snake_case + legacy names, placeholder interpolation, and collisions.
- [ ] Document the strategy in README/example (migration guide, configuration, YAML snippets) and ensure `dart analyze`/`dart test` cover the new parser branches.

### SDK capability abstraction layer
- [ ] Review `AnalyticsBase`, `IAnalytics`, and generated mixins to capture the current extension limitations (`logEvent`-only) and list the provider-specific scenarios we must enable (user properties, timed events, revenue APIs, attribution).
- [ ] Define a capability-driven adapter API (e.g., `AnalyticsCapability`, `AnalyticsAdapter`, `AnalyticsClient`) so providers can expose advanced features without leaking SDK types into generated code; sketch the dependency graph to keep SOLID boundaries.
- [ ] Update runtime core (`AnalyticsBase`, `Analytics.initialize`, generator outputs) to route `logEvent` through the adapter layer while exposing safe capability lookups for custom hooks; provide default no-op adapters to keep backward compatibility.
- [ ] Add targeted unit tests + example wiring that demonstrate requesting a timed-event capability and setting user properties; include docs describing how to implement custom adapters and how to access them from app code.

## Notes
- Tests must also keep covering the export cleanup + analytics plan metadata; broaden them once the new naming strategy and capability adapters land.
- README updates should mention the runtime plan constant, refined watch/export behaviors, and the newly added naming/capability customization knobs.
