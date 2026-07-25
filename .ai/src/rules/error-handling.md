---
paths:
  - "lib/**/*.dart"
  - "bin/**/*.dart"
  - "test/**/*.dart"
---

# Error Handling Rules

## Library Boundaries

- Raise `AnalyticsParseException` for malformed event, context, shared-parameter, or
  schema-derived YAML and attach the source location when available.
- Raise `AnalyticsGenerationException` when generation cannot produce a valid
  artifact and include the originating path or line when known.
- Use `ArgumentError.value` for invalid programmatic arguments and `StateError` for
  invalid lifecycle state, matching the runtime and generated APIs.
- Preserve compatibility with callers that catch `FormatException` when changing
  parse failures.

## Recovery

- Catch an error only when adding source context, aggregating independent failures,
  isolating provider failures, or converting it at a CLI boundary.
- Preserve the original error and stack trace when wrapping asynchronous generation
  task failures.
- Let reusable services return or throw; keep logging plus `exit(1)` at established
  command and pipeline entry points.
- Keep best-effort provider delivery behavior explicit through existing failure
  handlers; do not silently convert delivery failures into success.

## Diagnostics

- Log through `Logger` and scoped loggers so tests can use `NoOpLogger` or recording
  implementations.
- Include task, file, domain, event, or provider context that helps locate a failure.
- Keep stack traces behind verbose CLI behavior and keep event payload PII out of
  diagnostic output.
