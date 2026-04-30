# Analytics Gen

Dart CLI code generator for type-safe analytics. Reads YAML event definitions, generates Dart code, docs, exports.

## Project structure

```
schema/              — SSOT: JSON schemas for all YAML formats
lib/                 — Dart library (main product)
  src/cli/           — CLI commands
  src/config/        — Config parsing
  src/core/          — Core logic
  src/generator/     — Code generation
  src/models/        — Data models
  src/parser/        — YAML parsing
  src/pipeline/      — Build pipeline
  src/services/      — Services
  src/util/          — Utilities
bin/                 — CLI entry point
templates/           — Code generation templates
test/                — Dart tests
analytics-gen-studio/ — Web studio (React/Vite)
```

## Schema = Single Source of Truth

`schema/*.json` defines all YAML formats. Everything else is derived:

- **Dart library** — parses YAML according to schemas
- **Studio site** — renders UI dynamically from schemas at runtime
- **TypeScript types** — auto-generated from schemas (`npm run generate-types`)

**To add a field/type/option** — edit the schema. Everything else updates automatically. Studio must not contain hardcoded models, data, or schema values — it purely renders what schemas define.

## What is generated from schemas

| Artifact | Command |
|----------|---------|
| **Templates** (`templates/*.yaml`) | `dart run scripts/generate_templates.dart` |
| **Schema docs** (`doc/SCHEMA_REFERENCE.md`) | `dart run scripts/generate_schema_docs.dart` |
| **Studio TypeScript types** | `cd analytics-gen-studio && npm run generate-types` |
| **Studio UI** | Reads schemas at runtime — no generation needed |

## Key rules

- Never hardcode schema-derived values anywhere — schemas are the SSOT
- Studio: use `schemas/constants.ts` and `schemas/loader.ts`, ConfigTab renders dynamically
- Templates and docs: regenerate after schema changes via scripts above
- `npm run build` in studio: copies schemas → generates types → builds
- YAML generation is generic (iterates object keys, not hardcoded field names)

## Pre-push validation

Before declaring work done or pushing, run the same checks CI runs. **`npm test` alone is NOT enough** — vitest uses esbuild and skips strict TypeScript checking, so type errors slip through locally and break the `Deploy Studio` workflow.

Run all of these:

```bash
# Dart side
dart analyze lib/ bin/ test/
dart test

# Studio side — both required
cd analytics-gen-studio
npm test -- --run
npx tsc -b              # ← catches type errors vitest misses
```

When you add a field to a schema and it lands in `Required<…>` types (e.g. `Required<GenerationTargets>`), every test fixture / mock with that type needs the new field — `tsc -b` is what surfaces this.

Or just run `/validate` — it bundles all of the above.
