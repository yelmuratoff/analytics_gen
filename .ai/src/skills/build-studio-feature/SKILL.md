---
name: "build-studio-feature"
description: >-
  Use this skill when adding or fixing Analytics Gen Studio UI, editor state,
  validation, schema-driven forms, YAML preview/import/export, project persistence,
  file-system access, undo/redo, accessibility, or React component behavior—even when
  phrased as "the web editor is broken", "add a field to the form", "save this
  project", "validation does not focus the item", or "the YAML round-trip changed".
---

# Build Studio Feature

Implement Studio behavior while preserving schema-driven contracts and lossless
project/YAML round-trips.

## Checklist

- [ ] Trace the behavior through schema, types, store, hook/utility, and component.
- [ ] Choose store state versus local presentation state deliberately.
- [ ] Add a focused Vitest regression test.
- [ ] Implement with existing MUI, RJSF, and Zustand patterns.
- [ ] Verify accessibility and validation navigation.
- [ ] Run tests, lint, type-check, and build.

## Steps

1. Read `analytics-gen-studio/src/App.tsx`, the affected component, its nearest hook
   or utility, `src/state/store.ts`, and the matching tests.
2. Check whether the behavior is contract-derived. If it changes a schema field,
   default, enum, constraint, or generated type, invoke `change-schema-contract`
   before editing the UI.
3. Put project-wide editor data and mutations in the Zustand store. Keep transient
   visual state local when it does not affect export, selection, persistence, undo,
   or another component.
4. Mutate nested store structures through the existing Immer-backed actions and keep
   load/reset behavior compatible with versioned Studio project files.
5. Reuse MUI controls, RJSF templates, shared editors, confirmation dialogs, file
   trees, and item-menu patterns already present in `src/components/`.
6. Keep validation rules in schema metadata or shared validation logic. Preserve
   navigation fields used to focus a file, domain, event, parameter, or context
   property from an error.
7. Keep import/export transforms pure under `src/utils/`. Preserve:
   - null shared references as `key:` in YAML
   - compact type-only parameter syntax
   - stable file names and project IDs
   - deterministic content revisions without timestamps
8. Add tests at the lowest effective boundary:
   - store action/round-trip tests under `src/__tests__/state/`
   - schema tests under `src/__tests__/schemas/`
   - validation tests under `src/__tests__/hooks/`
   - serialization/import/export tests under `src/__tests__/utils/`
   - Testing Library tests for interaction and accessibility behavior
9. Run:

   ```sh
   npm --prefix analytics-gen-studio test
   npm --prefix analytics-gen-studio run lint
   npm --prefix analytics-gen-studio exec -- tsc -b
   dart doc
   npm --prefix analytics-gen-studio run build
   ```

10. Inspect the built and generated diff. Commit source changes and intentional
    checked-in contract artifacts; treat `dist/` as build output.

## Gotchas

- `src/types/generated.ts` is generated; add narrow UI aliases in `src/types/index.ts`
  only when the schema type needs a Studio-specific composition.
- The validation store is module-level, debounced, and shared through
  `useSyncExternalStore`; tests must reset modules or state when cached snapshots
  could leak.
- Browser file handles are not serializable project data. Keep handle persistence in
  `src/utils/file-handle-store.ts` and preserve browsers without File System Access.
- YAML generation intentionally replaces `: null` with `:` for shared references and
  omits empty optional values; round-trip tests should assert this syntax.
- The production build copies schemas and generated Dart API docs before compiling,
  so `dart doc` must exist when verifying the complete Studio build.
