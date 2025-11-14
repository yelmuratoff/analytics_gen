# TODO – `analytics_gen`

High-level goal: keep the package small and focused while improving DX, safety, and analytics best practices.

## 1. Library vs CLI logging

- [x] Avoid unconditional `print` inside library code (`YamlParser`, generators, services) by allowing an optional logger callback.
- [x] Introduce a simple logging abstraction or `verbose` flag for:
  - [x] `YamlParser`
  - [x] `CodeGenerator`
  - [x] `DocsGenerator`
  - [x] `ExportGenerator` / `SqliteGenerator`
  - [x] `MultiProviderAnalytics` error reporting
- [ ] Keep rich, user-friendly output in `bin/generate.dart` (CLI) and route library logs through it.

## 2. Value types for core models

- [x] Add `==` / `hashCode` implementations for:
  - [x] `AnalyticsParameter`
  - [x] `AnalyticsEvent`
  - [x] `AnalyticsDomain`
- [ ] Consider small helper to compute hashes consistently.
- [ ] Add tests that compare instances and use the models in sets/maps.

## 3. YAML parsing robustness

- [x] Validate YAML structure explicitly and fail fast with clear errors:
  - [x] Domain values must be `YamlMap`.
  - [x] Event values must be `YamlMap`.
  - [x] `parameters`, when present, must be `YamlMap`.
  - [x] Provide the source file and key path in error messages (at least domain + event and file path).
- [x] Use a dedicated exception type (`FormatException`) rather than generic errors for malformed structures.
- [x] Extend `test/parser/yaml_parser_test.dart` with malformed YAML cases and assertions on error messages.

## 4. Public API typing and ergonomics

- [x] Introduce `typedef AnalyticsParams = Map<String, Object?>;`.
- [x] Switch `IAnalytics.logEvent` and generated methods to use `AnalyticsParams?` where appropriate.
- [x] Document expectations in `README.md` (values should be serializable).
- [ ] Evaluate (and document) whether `logEvent` should remain sync or eventually be `Future<void>`.

## 5. Domain/file naming and constraints

- [ ] Decide on and document allowed domain key format (e.g. snake_case, filesystem-safe).
- [ ] Either:
  - [ ] Enforce constraints at parse time with clear errors, or
  - [ ] Normalize domain names for file/class generation while keeping original label in analytics payloads.
- [ ] Add tests for odd domain names to ensure behavior is stable.

## 6. CLI UX refinements

- [ ] Revisit `--code`, `--docs`, `--exports` semantics:
  - [ ] Allow “docs only” / “exports only” flows (e.g. negatable flags or explicit modes).
  - [ ] Add `--verbose` / `--quiet` flags to control generator logging noise.
- [ ] Add tests (or golden outputs) for argument parsing in `bin/generate.dart`.

## 7. Generator and export tests

- [ ] Add targeted tests for:
  - [x] `CodeGenerator.generate` (creates expected files and signatures).
  - [ ] `DocsGenerator.generate` (domain/event rows, example calls).
  - [x] `ExportGenerator` + `JsonGenerator` (metadata counts, parameters).
  - [ ] `SqlGenerator` (presence of tables, indexes, and inserts).
  - [ ] `SqliteGenerator` (behavior when `sqlite3` is present vs missing; ideally with an injectable process runner).
- [ ] Use temp directories in tests, similar to parser tests.

## 8. Multi-provider error handling

- [ ] Improve `MultiProviderAnalytics` error handling:
  - [ ] Catch `Object` and log a short stack trace.
  - [ ] Optionally accept `void Function(Object error, StackTrace stackTrace)? onError`.
- [ ] Add tests verifying that:
  - [ ] One failing provider does not prevent others from receiving events.
  - [ ] The error handler is invoked as expected (if added).

## 9. Documentation and analytics best practices

- [ ] Add a short “analytics best practices” section to `README.md` / `example/README.md`:
  - [ ] Naming conventions for events and parameters.
  - [ ] Guidance on cardinality (avoid raw IDs where not needed).
  - [ ] One domain per file / clear ownership.
- [ ] Document new flags / types (logger behavior, `AnalyticsParams`, etc.).

## 10. Small internal polish

- [ ] Extract shared helpers (`_capitalize`, `_toCamelCase`) into a small internal util.
- [x] Align `MockAnalyticsService` parameter type with `IAnalytics` (`AnalyticsParams`), and document its intended usage in tests.
- [ ] Run `dart analyze` and `dart test` kept green after each change.
