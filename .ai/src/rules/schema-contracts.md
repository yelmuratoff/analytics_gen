---
paths:
  - "schema/**/*.json"
  - "templates/**/*.yaml"
  - "scripts/generate_schema_docs.dart"
  - "scripts/generate_templates.dart"
  - "scripts/sync.sh"
  - "lib/src/config/**/*.dart"
  - "lib/src/parser/**/*.dart"
  - "lib/src/util/yaml_keys.dart"
  - "analytics-gen-studio/public/schemas/**/*.json"
  - "analytics-gen-studio/src/schemas/**/*.ts"
  - "analytics-gen-studio/src/types/**/*.ts"
---

# Schema Contract Rules

## Canonical Changes

- Change `schema/*.json` first when adding or changing configuration, event,
  parameter, shared-parameter, or context fields.
- Mirror every schema key used by Dart parsing in `lib/src/util/yaml_keys.dart`.
- Keep legacy aliases marked with `x-alias-for`; preserve the nested canonical field
  when both alias and nested forms are accepted.
- Put form hints in `x-ui` and cross-field constraints in `x-constraints` so the
  Studio can derive behavior instead of hardcoding schema values.
- Treat event identifiers, parameter types, nullability, enum values, export columns,
  and defaults as compatibility-sensitive contract changes.

## Regeneration Sequence

- Run `dart run scripts/generate_templates.dart` after schema changes.
- Run `dart run scripts/generate_schema_docs.dart` after schema changes.
- Run `npm --prefix analytics-gen-studio run copy-schemas` before generating Studio
  types or testing schema loading.
- Run `npm --prefix analytics-gen-studio run generate-types` and edit neither
  `analytics-gen-studio/src/types/generated.ts` nor copied public schemas by hand.
- Finish with `./scripts/sync.sh` and inspect all derived diffs.

## Validation

- Add Dart parser or schema tests for accepted and rejected contract values.
- Add Studio schema-loader or validation tests when metadata changes form behavior.
- Preserve the Studio loader's raw config schema alongside its prepared editor schema.
- Keep JSON schemas valid and keep the sync script's schema-to-`YamlKeys`
  cross-reference green.
