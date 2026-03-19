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

**To add a field/type/option** — edit the schema. Studio picks it up automatically. Studio must not contain hardcoded models, data, or schema values — it purely renders what schemas define.

## Key rules

- Never hardcode schema-derived values in Studio — use `schemas/constants.ts` and `schemas/loader.ts`
- Studio ConfigTab renders dynamically from `configSchema.properties`
- `npm run build` in studio: copies schemas → generates types → builds
- YAML generation is generic (iterates object keys, not hardcoded field names)
