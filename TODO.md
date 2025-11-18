# TODO – `analytics_gen`

## Active Work Items

### Documentation split + review guardrails
- [x] Wire a PR template (or CI reminder) that links to the new checklist so contributors cannot skip the required review steps. _PR template added under `.github/` with guardrail tests._

### Runtime & API surface
- [x] Evaluate whether `IAnalytics.logEvent` should expose an async variant by default (beyond `AsyncAnalyticsAdapter`) or if stronger documentation around handling heavy providers suffices. _Kept the synchronous interface + added README/Onboarding guidance and example usage + tests, emphasizing queueing patterns via `AsyncAnalyticsAdapter`._
- [ ] Investigate native batch logging support (buffer + flush strategies) so apps can optimize network usage without hand-rolling adapters. Define API shape + provider contract if feasible.
- [ ] Revisit provider capability ergonomics to reduce boilerplate (templates, mixins, or helper base classes) and ensure the abstraction does not feel like lock-in. Could be documentation with ready-to-copy snippets or new helpers.

### Examples & guidance
- [ ] Expand `example/` into a realistic Flutter showcase (UI + analytics wiring) and publish its pubspec so developers can run a full app, not just scripts.
- [ ] Author migration guides for common sources (Firebase Analytics manual strings, Amplitude, Mixpanel) covering mapping events → YAML, verifying generated diffs, and rollout strategy.
- [ ] Deepen the FAQ/docs explaining why YAML was chosen over a Dart DSL, including pros/cons and mitigation strategies (e.g., generators wired into CI). Clarify compile-step implications.

### Configuration & compatibility
- [ ] Audit dependency constraints (`yaml`, `path`, `args`, etc.) to decide whether tighter pinning or caret updates make sense; document rationale so consumers know compatibility expectations.
- [ ] Reassess the minimum supported Dart SDK (currently 3.6.0). If the codebase can compile on 3.3/3.4, lower the constraint and add CI coverage; otherwise, document why 3.6 features are required.
- [ ] Document + measure scalability characteristics (parse/generate times, memory) for large plans (100+ domains / 1000+ events) so enterprises understand limits and tuning options.
## Notes
- Tests must also keep covering the export cleanup + analytics plan metadata; broaden them once the new naming strategy and capability adapters land.
- README updates should mention the runtime plan constant, refined watch/export behaviors, and the newly added naming/capability customization knobs.
