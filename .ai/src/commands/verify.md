---
description: >-
  Run the smallest complete analytics_gen quality gate for the requested scope and
  report evidence.
argument-hint: "<dart|studio|schema|all>"
---

Verify `$ARGUMENTS` changes without modifying product behavior.

1. Inspect `git status --short` and `git diff --name-only` to determine the actual
   affected stack. Treat an omitted scope as `all` only when changes cross stacks.
2. For Dart, run the format check, `dart analyze --fatal-infos`, and the relevant
   focused tests before `dart test`.
3. For Studio, run `npm --prefix analytics-gen-studio test`,
   `npm --prefix analytics-gen-studio run lint`, and
   `npm --prefix analytics-gen-studio exec -- tsc -b`.
4. For schema or cross-stack changes, run `./scripts/sync.sh`; it owns the required
   regeneration and contract cross-reference sequence.
5. For Studio production build verification, run `dart doc` before
   `npm --prefix analytics-gen-studio run build`.
6. Re-run failed checks after fixing only issues caused by the current change.
7. Report each command and result, any skipped check with a concrete reason, and any
   pre-existing failure separated from change-related failures.
