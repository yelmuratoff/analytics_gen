---
name: generate-all
description: Regenerate everything from schemas — templates, docs, Studio types. Run after changing any schema file. Trigger on "/generate-all".
---

# Generate All

Regenerate all schema-derived artifacts.

## Steps (run in parallel where possible)

1. **Templates**: `dart run scripts/generate_templates.dart`
2. **Schema docs**: `dart run scripts/generate_schema_docs.dart`
3. **Studio build**: `cd analytics-gen-studio && npm run build`
   (This internally runs: copy-schemas → generate-types → tsc → vite build)

## Report

```
Templates:    ✓ templates/*.yaml
Schema docs:  ✓ doc/SCHEMA_REFERENCE.md
Studio types: ✓ src/types/generated.ts
Studio build: ✓ dist/
```
