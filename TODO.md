# TODO – `analytics_gen`

High-level focus: ship high-signal improvements raised during the last review and keep DX/tests/docs aligned as we go.

## Active Work Items

- [x] Clean generated output before each run so stale domain files disappear automatically — `CodeGenerator` now wipes `events/`, covered by `code_generator_test.dart`, and README calls out the self-cleaning behavior.
- [ ] Make docs/JSON/SQL exports deterministic by replacing `DateTime.now` with reproducible metadata (generator changes + tests + README).
- [ ] Surface event deprecation info directly in generated docs (DocsGenerator + fixtures + README screenshot).
- [ ] Enrich parameters with privacy tiers (`public`, `pii`, `sensitive`) and thread through exports + generated code (model/parser changes + tests + README usage).
- [ ] Improve `MultiProviderAnalytics` error handling (logging, metrics hooks) so failed providers don’t silently lose events (service + tests + guide).

## Process

- Keep README and example docs fresh as features change.
- Every change must land with focused unit tests (`dart test`).
- Update this TODO after completing each item (check the box + summarize work/tests/docs touched).
- Add changes to CHANGELOG.md as features land.
