---
name: sync-studio
description: Verify Studio site is fully in sync with schemas. Build, test, check for hardcoded values. Trigger on "/sync-studio".
---

# Sync Studio

Ensure analytics-gen-studio is 100% schema-driven.

## Steps

1. Copy schemas: `cp schema/*.json analytics-gen-studio/public/schemas/`
2. Generate types: `cd analytics-gen-studio && npm run generate-types`
3. Run TypeScript check: `npx tsc --noEmit`
4. Run tests: `npx vitest run`
5. Run build: `npm run build`
6. Scan for hardcoded schema values:
   ```
   grep -rn for hardcoded types, operations, field names, defaults
   in src/ excluding __tests__, generated, constants, schemas/
   ```
7. Report any findings — Studio must not contain hardcoded models or schema data.

## If issues found

Fix them by:
- Moving values to `schemas/constants.ts` (populated at runtime from schemas)
- Using `schemas/loader.ts` extraction functions
- Never hardcoding schema field names, types, enums, or defaults in components
