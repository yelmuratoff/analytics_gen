---
description: >-
  Investigate and fix an analytics_gen GitHub issue with a regression test and
  scope-appropriate verification.
argument-hint: "<issue-number>"
---

Investigate and fix issue #$ARGUMENTS in this repository.

## Issue

!`gh issue view $ARGUMENTS --comments`

1. Confirm the reported behavior and identify whether it belongs to the Dart package,
   schema contract, generated artifacts, or `analytics-gen-studio/`.
2. Read the affected entry point plus nearby implementation and tests. Trace
   cross-stack impact before editing.
3. Reproduce the failure with the narrowest automated test. Preserve source-aware
   parse errors, deterministic output, and public API compatibility.
4. Implement the smallest complete fix using existing parsers, pipeline tasks,
   renderers, Zustand actions, schema metadata, or utilities as appropriate.
5. If `schema/*.json` changes, regenerate templates, schema docs, copied Studio
   schemas, and TypeScript types in the repository-defined order.
6. Run the focused test, relevant analyzer/lint/type checks, and both stacks when the
   issue crosses their contract.
7. Review `git diff` for unrelated edits, stale generated files, accidental public
   API changes, or contract migrations not requested by the issue.
8. Summarize the root cause, fix, tests run, and any consumer migration impact.
