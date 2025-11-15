# TODO – `analytics_gen`

High-level focus: build on the existing generator by adding stricter parameter validation and more accurate typing, then document and test those improvements.

## Active Work Items
- [x] Add runtime guards for parameters that declare `allowed_values` so invalid calls fail fast.
- [x] Respect literal YAML `type` names when generating method signatures so custom/documented types are preserved.
- [x] Cover the new behavior with code generator tests that assert the guard logic and custom types show up in generated files.
- [x] Document the new validation/type guarantees in `README.md` so users know how to rely on them.

## Process
- Update this TODO after completing each item (check the box and record the test/README coverage), so the plan stays accurate.
- Every code change must be accompanied by a focused unit test and README mention as requested.
- Tests: `dart test` (at least the relevant suites) before finishing the work.
