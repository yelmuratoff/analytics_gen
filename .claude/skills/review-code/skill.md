---
name: review-code
description: Review Dart library code for quality, architecture, SOLID, test coverage, and consistency with schemas. Trigger on "/review-code" or "/review-code <path>".
---

# Review Code

Review Dart library code for quality and correctness.

## If path is given

Review only that file/directory. Check:
- SOLID principles (single responsibility, dependency inversion)
- Error handling (specific exceptions, no silent catches)
- Immutability (final fields, no mutable state leaks)
- Naming (follows project conventions: snake_case files, PascalCase classes)
- Test coverage (is there a corresponding test file?)
- Schema alignment (do models/parsers match schema definitions?)

## If no path given

Broad review — pick the most impactful areas:
1. `lib/src/parser/` — does parsing handle all schema fields correctly?
2. `lib/src/generator/renderers/` — does code generation cover all model fields?
3. `lib/src/models/` — are models complete, immutable, with equality?
4. `lib/src/config/` — does config parsing match schema defaults?

## Output format

For each issue found:
```
[SEVERITY] file:line — description
  Suggestion: ...
```

Severities: CRITICAL (breaks functionality), HIGH (bug risk), MEDIUM (quality), LOW (style)
