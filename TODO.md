# TODO – `analytics_gen`

## Code Quality & Strict Refactoring (Priority: High)
- [x] **Remove `GenerationTelemetry`** (YAGNI/Bloat)
  - The telemetry system provides little value for a local CLI tool and complicates the generator logic.
- [x] **Harden `AnalyticsConfig` Parsing** (Safety)
  - Replace unsafe `as Type` casts with robust type checking helpers to prevent runtime crashes on malformed YAML.
- [x] **Refactor Interpolation Logic** (SRP)
  - Move string interpolation regex logic from `EventRenderer` (View) to `EventParser` (Controller/Model) to respect Separation of Concerns.

## Developer Experience & Safety Improvements

- [x] **1. Generated Test Matchers**
  - Problem: Testing analytics requires brittle mocks.
  - Solution: Generate typed Matchers for `package:test`.

- [x] **2. "Dead Event" Audit Command**
  - Problem: Unused events clutter the codebase.
  - Solution: Add `dart run analytics_gen:audit` command.

- [x] **6. Configurable Event Naming Strategy**
  - Problem: Default `domain: event` naming is an anti-pattern (hard to group/filter).
  - Solution: Add configurable naming strategy (default: `snake_case`).
    - Support "Engineer Friendly" (`snake_case`) for SQL/DB.
    - Support "Business Readable" (`Title Case`) for non-tech dashboards.
- [x] Type-Safe Dart Enum Mapping (`dart_type`)
- [x] Custom Imports Support (`imports` global + `import` local)**
  - Problem: Passing Dart enums to analytics requires `.name` everywhere.
  - Solution: Support `dart_type` in YAML parameter definition.


## Architecture & Refactoring (v2.0 Prep)

- [x] **Refactor Models (SRP Violation)**
  - Problem: `AnalyticsEvent` and `AnalyticsParameter` contain complex YAML parsing logic.
  - Solution: Extract parsing into `EventParser` / `ParameterParser` or `YamlMapper`. Models should be dumb data containers.

- [x] **Refactor Renderer (God Object)**
  - Problem: `EventRenderer` handles doc gen, method signatures, validation, and body logic in one massive class.
  - Solution: Decompose into `DocumentationRenderer`, `MethodSignatureRenderer`, `ValidationRenderer`.

- [ ] **Optimize Generated Code**
  - Problem: `Map` creation logic is redundant/allocating.
  - Solution: Use `const` where possible, optimize map creation for high-load paths.