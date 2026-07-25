---
description: >-
  Review the current branch for analytics_gen correctness, contract drift, and
  missing verification before merge.
---

Review the current branch against `main`.

## Changed files

!`git diff --name-only main...HEAD`

## Diff

!`git diff --find-renames main...HEAD`

Prioritize actionable defects:

1. Trace schema changes through `YamlKeys`, Dart parsing/models, templates, schema
   docs, Studio schema copies, generated TypeScript types, and Studio behavior.
2. Check generated output for deterministic ordering, stable fingerprints/revisions,
   correct escaping, managed-file cleanup, and public API compatibility.
3. Check Dart errors for typed exceptions, source context, preserved causes/stacks,
   and process exits confined to CLI boundaries.
4. Check Studio state, import/export round-trips, validation navigation, accessibility,
   and schema-derived defaults.
5. Verify tests cover behavior and failure paths at the narrowest useful boundary.
6. Compare claimed checks with `.github/workflows/ci.yml`,
   `.github/workflows/format-check.yml`, and `doc/CODE_REVIEW.md`.

Report findings first, ordered by severity. Include exact file and line, the failure
scenario, and a concrete fix. Distinguish confirmed defects from questions. If there
are no findings, state: `This is production-ready. No changes needed.`
