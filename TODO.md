# TODO – `analytics_gen`

## Active Work Items

### Flexible naming + uniqueness customization
- [x] Audit current snake_case enforcement and uniqueness constraints (parser validation in `lib/src/parser/yaml_parser.dart`, normalization helpers in `lib/src/util/string_utils.dart`, resolve logic in `lib/src/util/event_naming.dart`, plus README/test coverage) to know exactly where the rules are coupled and what needs abstractions.
- [x] Design a `NamingStrategy` (config + value object) that lets users opt into legacy naming (e.g., relaxed validation, domain aliases, per-event `identifier`, overridable `<domain>: <event>` template) while keeping the existing behavior as the default.
- [x] Extend the YAML schema + parser to honor the new strategy (`analytics_gen.naming` block, optional `identifier`/`param_name` overrides) without breaking generated Dart identifiers; surface precise errors when overrides conflict after normalization.
- [x] Update unique event-name resolution to rely on the configured template/override rules, and add regression tests covering mixed snake_case + legacy names, placeholder interpolation, and collisions.
- [x] Document the strategy in README/example (migration guide, configuration, YAML snippets) and ensure `dart analyze`/`dart test` cover the new parser branches.

### SDK capability abstraction layer
- [x] Review `AnalyticsBase`, `IAnalytics`, generated mixins, and existing services (`MockAnalyticsService`, `MultiProviderAnalytics`, `AsyncAnalyticsAdapter`) to confirm we only expose `logEvent`/`logEventAsync` today and lack hooks for provider-specific capabilities (user properties, timed events, revenue APIs, attribution APIs).
- [x] Define a capability-driven adapter API (e.g., `AnalyticsCapability`, `AnalyticsAdapter`, `AnalyticsClient`) so providers can expose advanced features without leaking SDK types into generated code; sketch the dependency graph to keep SOLID boundaries.
- [x] Update runtime core (`AnalyticsBase`, `Analytics.initialize`, generator outputs) to route `logEvent` through the adapter layer while exposing safe capability lookups for custom hooks; provide default no-op adapters to keep backward compatibility.
- [x] Add targeted unit tests + example wiring that demonstrate requesting a timed-event capability and setting user properties; include docs describing how to implement custom adapters and how to access them from app code.

### Onboarding & documentation improvements
- [x] streamline README structure so juniors can follow a “define YAML → run generator → use API” flow without jumping around; surface concise checklists at the top.
- [x] Add a practical walkthrough (with screenshots/snippets) covering YAML authoring, common validation errors, and how to read generated mixins/analytics singleton.
- [x] Highlight provider-capability extension points (once built) with simple Firebase/Amplitude examples so teams understand how to wire advanced APIs.

### Documentation split + review guardrails
- [x] Break the long-form README into focused docs (`docs/ONBOARDING.md`, `docs/VALIDATION.md`, `docs/CAPABILITIES.md`) and keep the README scoped to essentials + links.
- [x] Document the capability pattern in beginner-friendly language with concrete provider + consumer snippets so juniors understand why capability keys exist.
- [x] Introduce a `docs/CODE_REVIEW.md` checklist so PR reviewers know exactly what to inspect across YAML, generated code, docs, and exports.
- [ ] Wire a PR template (or CI reminder) that links to the new checklist so contributors cannot skip the required review steps.

## Notes
- Tests must also keep covering the export cleanup + analytics plan metadata; broaden them once the new naming strategy and capability adapters land.
- README updates should mention the runtime plan constant, refined watch/export behaviors, and the newly added naming/capability customization knobs.
