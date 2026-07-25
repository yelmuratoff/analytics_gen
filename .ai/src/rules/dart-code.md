---
paths:
  - "lib/**/*.dart"
  - "bin/**/*.dart"
  - "test/**/*.dart"
  - "scripts/**/*.dart"
  - "tool/**/*.dart"
---

# Dart Code Rules

## Conventions

- Follow `analysis_options.yaml`, including explicit return types, final locals,
  single quotes, directive ordering, and public API documentation.
- Use package imports across `lib/src/` modules; match nearby relative-import usage
  only within an existing tightly coupled module.
- Prefer final or sealed classes when the code models a closed implementation or
  state space, as in the existing exception hierarchy.
- Keep models immutable and implement value equality manually where repository tests
  compare instances by data.
- Use named required parameters for collaborators and values whose call-site meaning
  is not obvious.

## Parsing and Generation

- Preserve `SourceSpan`, `filePath`, and `innerError` when translating YAML failures
  into `AnalyticsParseException`.
- Aggregate independent domain parse failures with `AnalyticsAggregateException`
  rather than stopping at the first file.
- Build generated Dart with the existing buffers, renderers, and import manager;
  preserve stable ordering so repeated generation is byte-for-byte deterministic.
- Keep generated validation messages specific enough to identify the invalid value
  and its contract.

## Documentation

- Add `///` documentation to public members because `public_member_api_docs` is
  enforced.
- Use comments for source-of-truth relationships, external quirks, or sequencing
  constraints; express ordinary behavior through names and small functions.
- Keep script headers accurate about their canonical inputs and generated outputs.
