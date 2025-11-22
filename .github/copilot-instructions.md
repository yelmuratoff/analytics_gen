# GitHub Copilot Instructions for analytics_gen

You are an expert Dart/Flutter engineer working on `analytics_gen`, a CLI tool that generates type-safe analytics code from YAML definitions.

## Project Overview
- **Goal**: Generate type-safe Dart APIs, documentation, and exports from YAML tracking plans.
- **Core Architecture**:
  - **Pipeline**: `EventLoader` (IO) -> `YamlParser` (Model) -> `CodeGenerator` / `DocsGenerator` (Output).
  - **Runtime**: Generated code uses `Analytics` singleton, `IAnalytics` interface, and `CapabilityProviderMixin`.
  - **State**: Stateless generation pipeline; `Analytics` singleton manages runtime state.

## Architectural Patterns
- **Domain-Driven Design**:
  - `src/models`: Immutable data models (`AnalyticsEvent`, `AnalyticsParameter`) representing the parsed plan.
  - `src/parser`: Pure parsing logic, separated from IO.
  - `src/generator`: Renderers for different outputs (Dart, Markdown, CSV).
- **Code Generation**:
  - Use `StringBuffer` for efficient string concatenation.
  - Prefer `mixin` for domain-specific logic (e.g., `AnalyticsAuth` on `AnalyticsBase`).
  - Ensure deterministic output (sort keys, stable ordering).
- **Runtime Library**:
  - `IAnalytics`: The core interface for providers.
  - `CapabilityProviderMixin`: For extending functionality (e.g., user properties) without polluting the base interface.
  - `AsyncAnalyticsAdapter` / `BatchingAnalytics`: Wrappers for async/batching behavior.

## Development Workflow
- **Running the Generator**:
  - `dart run analytics_gen:generate` (default)
  - `dart run analytics_gen:generate --watch` (dev mode)
  - `dart run analytics_gen:generate --validate-only` (CI check)
- **Testing**:
  - **Integration Tests**: Create temporary directories, write YAML, run generator, assert on file existence and content (see `test/generator/code_generator_test.dart`).
  - **Unit Tests**: Test parsers and models in isolation.
  - **Run Tests**: `dart test`
- **Linting**:
  - Follow `analysis_options.yaml`.
  - Key rules: `prefer_single_quotes`, `sort_constructors_first`, `public_member_api_docs`.

## Coding Conventions
- **Dart**:
  - Use `final` for all variables and fields unless mutability is strictly required.
  - Use `const` constructors for immutable data classes.
  - Prefer `sealed` classes for finite state hierarchies, use new coding patterns, like pattern matching where applicable.
  - Use `Future<void>` for async commands, never `void`.
- **YAML Parsing**:
  - Handle missing keys gracefully with defaults.
  - Validate types strictly (`int`, `string`, `bool`).
  - Support `meta` fields for extensibility.
- **Error Handling**:
  - Throw specific exceptions (e.g., `AnalyticsGenerationException`) with helpful messages.
  - Catch errors at the top level (`AnalyticsGenRunner`) and exit with status 1.

## Key Files
- `bin/generate.dart`: CLI entry point.
- `lib/src/config/analytics_config.dart`: Configuration model (`analytics_gen.yaml`).
- `lib/src/models/analytics_event.dart`: Core model for an event.
- `test/test_utils.dart`: Utilities for creating temp projects and loggers.
