---
name: "change-schema-contract"
description: >-
  Use this skill when adding, renaming, deprecating, or changing an analytics_gen
  configuration, event, parameter, shared-parameter, or context field; updating JSON
  schemas, YAML validation, Studio forms, generated TypeScript types, templates, or
  schema docs; or fixing drift between Dart and the Studio—even when phrased as
  "support this YAML option", "add this field", "the editor rejects it", or "schema
  and parser disagree".
---

# Change Schema Contract

Change the shared analytics contract and keep every derived consumer synchronized.

## Checklist

- [ ] Identify the canonical schema and compatibility impact.
- [ ] Update Dart keys, parsing, validation, and models.
- [ ] Regenerate templates, schema docs, Studio schemas, and TypeScript types.
- [ ] Update Studio-derived behavior where schema metadata is consumed.
- [ ] Add Dart and Studio regression tests.
- [ ] Run the cross-stack sync gate and inspect derived diffs.

## Steps

1. Read the relevant file in `schema/` and trace the field through:
   - `lib/src/util/yaml_keys.dart`
   - `lib/src/config/` or `lib/src/parser/`
   - `lib/src/models/`
   - `analytics-gen-studio/src/schemas/loader.ts`
   - `analytics-gen-studio/src/types/index.ts`
2. Decide whether the change is additive, deprecated, or breaking. Preserve existing
   nested fields and `x-alias-for` aliases unless the task explicitly includes a
   breaking migration.
3. Edit the canonical `schema/*.json`. Put editor presentation in `x-ui` and
   cross-field rules in `x-constraints` when the current loaders can derive them.
4. Add the field name to `lib/src/util/yaml_keys.dart` and update the relevant parser,
   immutable model, serialization, or naming strategy.
5. Raise `AnalyticsParseException` with file and span context for invalid YAML values.
   Keep accepted legacy forms covered by tests.
6. Update Studio loader extraction only when new metadata needs exposing. Prefer
   schema-derived constants over literals in components and hooks.
7. Regenerate in this order:

   ```sh
   dart run scripts/generate_templates.dart
   dart run scripts/generate_schema_docs.dart
   npm --prefix analytics-gen-studio run copy-schemas
   npm --prefix analytics-gen-studio run generate-types
   ```

8. Add focused Dart tests under `test/config/` or `test/parser/`. Cover valid input,
   invalid type/value, compatibility aliases, and source-aware errors as applicable.
9. Add Studio tests under `analytics-gen-studio/src/__tests__/schemas/`,
   `hooks/`, `state/`, or `utils/` when the contract changes editor behavior or
   serialization.
10. Run `./scripts/sync.sh`. Fix failures, repeat until green, then inspect:
    `git diff -- schema templates doc/SCHEMA_REFERENCE.md
    analytics-gen-studio/public/schemas analytics-gen-studio/src/types/generated.ts`.

## Gotchas

- `analytics-gen-studio/src/types/generated.ts` is generated from copied files in
  `analytics-gen-studio/public/schemas/`; copying schemas must precede type generation.
- The Studio keeps both a prepared config schema and `rawConfigSchema`; stripping the
  `analytics_gen` wrapper from the raw form breaks import/export.
- `parameter.schema.json` supports legacy type-as-key syntax through
  `additionalProperties`; the type generator intentionally strips that member before
  compiling TypeScript interfaces.
- `scripts/sync.sh` cross-checks schema fields against `YamlKeys`; a Studio-only edit
  cannot make a new contract field complete.
- Event identifiers, parameter nullability, defaults, and export columns can break
  downstream dashboards even when the Dart API still compiles.
