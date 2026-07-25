---
paths:
  - "analytics-gen-studio/src/**/*.ts"
  - "analytics-gen-studio/src/**/*.tsx"
  - "analytics-gen-studio/scripts/**/*.mjs"
  - "analytics-gen-studio/package.json"
---

# Studio Rules

## State and Contracts

- Use the existing Zustand store and Immer middleware for shared project mutations,
  undo/redo, active selections, and persistence-facing state.
- Keep `ConfigState`, event, parameter, shared-parameter, and context shapes aligned
  with `src/types/generated.ts` and the narrow aliases in `src/types/index.ts`.
- Load schemas through `src/schemas/loader.ts`; derive constants and editor schemas
  from schema metadata where the loader already exposes them.
- Preserve round-trip compatibility between imported Studio JSON, Zustand state,
  YAML generation, ZIP export, and Dart `StudioGenerator` output.

## UI

- Build controls with MUI and the existing RJSF templates and UI schemas.
- Keep accessible names on icon buttons and non-text controls; preserve keyboard
  navigation, visible focus, disabled states, and dialog focus behavior.
- Reuse the file tree, item menu, confirmation dialog, empty state, and parameter
  editor patterns before adding a parallel component family.
- Keep validation navigation metadata (`fileIndex`, domain, event, parameter, context
  property) intact so errors can focus the corresponding editor node.

## Behavior

- Keep YAML serialization deterministic and preserve null shared-parameter references
  as keys without a rendered `null` value.
- Use schema-derived defaults instead of duplicating literal default values in
  components or hooks.
- Add pure utility or store tests before component tests when behavior can be proven
  without rendering.
- Run Vitest, ESLint, TypeScript build mode, and the production build for Studio
  changes that cross state, schema, or export boundaries.
