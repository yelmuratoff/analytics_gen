# Testing Rules

## Dart Tests

- Place tests under the matching `test/<area>/` directory and name files
  `<subject>_test.dart`.
- Use `package:test`, local temporary directories, and collaborators supplied through
  constructors or factories.
- Test parser success and failure paths, including file path, line/span context, and
  aggregate behavior where relevant.
- Test generators with exact fragments or complete fixtures that prove signatures,
  imports, validation, ordering, and escaping.
- Add integration coverage under `test/integration/` when a change crosses config
  loading, YAML parsing, generation tasks, and filesystem output.
- Keep tests independent of real network access, user home state, wall-clock sleeps,
  and the current git checkout.

## Studio Tests

- Place Vitest tests under `analytics-gen-studio/src/__tests__/` by concern.
- Reset Zustand state and mocks in `beforeEach`; assert through public store actions
  and observable output.
- Mock schema fetches in loader tests and cover failed responses as well as prepared
  and raw schema forms.
- Prefer direct tests of stores, hooks, schema transforms, and serialization utilities;
  use Testing Library for user-visible component behavior.

## Verification

- Run the narrow test file while iterating.
- Run `dart test` for Dart behavior and `npm --prefix analytics-gen-studio test` for
  Studio behavior before handoff.
- Use `dart test --coverage=coverage` when a change materially expands business logic;
  inspect relevant coverage rather than optimizing a repository-wide number.
- Run `./scripts/sync.sh` for schema or cross-stack changes because it validates
  generation, analysis, both test suites, types, build, and contract cross-references.
