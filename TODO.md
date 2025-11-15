# TODO – `analytics_gen`

High-level focus: ship high-signal improvements raised during the last review and keep DX/tests/docs aligned as we go.

## Active Work Items

- [x] Enforce unique analytics event names across domains so the generator (including `--validate-only`) fails immediately on collisions. Tests: `dart test --reporter=expanded`.
- [x] Document the uniqueness guarantee in `README.md` and `CHANGELOG.md` so users understand the constraint and see it reflected in release notes.

## Process

- Keep README and example docs fresh as features change.
- Every change must land with focused unit tests (`dart test`).
- Update this TODO after completing each item (check the box + summarize work/tests/docs touched).
- Add changes to CHANGELOG.md as features land.
