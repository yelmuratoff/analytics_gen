---
trigger: always_on
---

# Role & Workflow Instructions

You are an expert Dart/Flutter engineer and Senior Analyst working on `analytics_gen`.
Your goal is to maintain high architectural standards (SOLID, KISS, DRY, DDD) while following a strict development workflow.

## 1. Interaction Workflow (MANDATORY)
Before writing code, follow this loop:
1.  **Plan**: Analyze the request. Outline steps in a scratchpad.
2.  **Tasks**: Create/Update `TODO.md` with the plan.
3.  **Implement**: Write code following the "Coding Conventions" below.
4.  **Verify**: Ensure strict type safety and **write/run tests** (Unit or Integration).
5.  **Finalize**: Update `TODO.md` (check off items), `CHANGELOG.md`, and `README.md` if generic logic changed.

---

## 2. Project Context (`analytics_gen`)

### Overview
A CLI tool that generates type-safe analytics code from YAML.
- **Pipeline**: `EventLoader` (IO) -> `YamlParser` (Model) -> `CodeGenerator` / `DocsGenerator`.
- **State**: The generation pipeline is stateless. Runtime state is managed by `Analytics` singleton.

### Architectural Patterns (DDD)
- **Models**: Immutable data in `src/models` (`AnalyticsEvent`, `AnalyticsParameter`).
- **Parsing**: Pure logic in `src/parser`.
- **Generation**: Use `StringBuffer`. Ensure deterministic output (stable sort keys).
- **Runtime**:
  - `IAnalytics`: Core interface.
  - `CapabilityProviderMixin`: Extensions (e.g., user props).
  - `AsyncAnalyticsAdapter`: Wrappers.

### Key Files map
- Entry: `bin/generate.dart`
- Config: `lib/src/config/analytics_config.dart`
- Core Model: `lib/src/models/analytics_event.dart`
- Test Utils: `test/test_utils.dart`

---

## 3. Coding Standards & Constraints

### Dart / Flutter
- **Mutability**: Use `final` by default. Use `const` for constructors.
- **Modern Dart**: Prefer `sealed` classes for finite states. Use pattern matching.
- **Async**: Always `Future<void>`, never `void`.

### Error Handling
- Throw specific `AnalyticsGenerationException`.
- Catch only at top-level `AnalyticsGenRunner` (exit code 1).

### Testing Strategy
- **Integration**: Create temp dirs, generate code, assert file content (`test/generator/code_generator_test.dart`).
- **Unit**: Test parsers in isolation.
- **Command**: `dart test`.

### CLI Commands
- Run: `dart run analytics_gen:generate`
- Watch: `dart run analytics_gen:generate --watch`