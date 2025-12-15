# TODO – `analytics_gen`

## Developer Experience & Safety Improvements

- [x] **1. Generated Test Matchers**
  - Problem: Testing analytics requires brittle mocks.
  - Solution: Generate typed Matchers for `package:test`.

- [x] **2. "Dead Event" Audit Command**
  - Problem: Unused events clutter the codebase.
  - Solution: Add `dart run analytics_gen:audit` command.

- [ ] **3. Custom Linter (`analytics_gen:lint`)**
  - Problem: Inconsistent naming/descriptions.
  - Solution: Add `dart run analytics_gen:lint` command.

- [ ] **4. Semantic PR Reports (Diff Generator)**
  - Problem: YAML diffs in PRs are hard to read.
  - Solution: Add `dart run analytics_gen:diff --base=main` command.

- [ ] **5. Automated Changelog (`ANALYTICS_CHANGELOG.md`)**
  - Solution: Auto-append to a `ANALYTICS_CHANGELOG.md` file during generation. Add ability to change from config.

- [x] **6. Configurable Event Naming Strategy**
  - Problem: Default `domain: event` naming is an anti-pattern (hard to group/filter).
  - Solution: Add configurable naming strategy (default: `snake_case`).
    - Support "Engineer Friendly" (`snake_case`) for SQL/DB.
    - Support "Business Readable" (`Title Case`) for non-tech dashboards.


- [x] Type-Safe Dart Enum Mapping (`dart_type`)
- [x] Custom Imports Support (`imports` global + `import` local)**
  - Problem: Passing Dart enums to analytics requires `.name` everywhere.
  - Solution: Support `dart_type` in YAML parameter definition.

## Notes
- Tests must also keep covering the export cleanup + analytics plan metadata; broaden them once the new naming strategy and capability adapters land.
- README updates should mention the runtime plan constant, refined watch/export behaviors, and the newly added naming/capability customization knobs.