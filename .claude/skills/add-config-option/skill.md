---
name: add-config-option
description: Add a new config option end-to-end — schema, config model, parser, pipeline integration, templates. Studio picks it up automatically. Trigger on "/add-config-option <section.field_name>" (e.g. "targets.openapi", "rules.require_descriptions").
---

# Add Config Option

Add a new configuration option to analytics_gen.yaml.

## Required argument

Section and field name (e.g. `targets.openapi`, `rules.require_descriptions`)

## Steps

1. **Schema** — add to `schema/analytics_gen.schema.json` → correct section properties
   - Include `type`, `title`, `description`, `default`

2. **Dart config model** — add to `lib/src/config/analytics_config.dart`
   - Add field to the correct class (AnalyticsTargets, AnalyticsRules, NamingStrategy, etc.)
   - Update constructor, equality, copyWith

3. **Dart config parser** — update `lib/src/config/config_parser.dart`
   - Parse the new field from YAML map

4. **Pipeline integration** — if the option controls behavior, update:
   - `lib/src/pipeline/generation_pipeline.dart` or relevant task
   - `lib/src/generator/` if it affects code generation

5. **Templates** — add example to `templates/analytics_gen.yaml` with comment

6. **Tests** — add/update in `test/config/`

7. **Studio** — nothing needed (ConfigTab renders dynamically from schema)

8. **Verify** — `dart analyze`, `dart test`, `cd analytics-gen-studio && npm run build`
