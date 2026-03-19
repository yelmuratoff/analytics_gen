---
name: add-event-field
description: Add a new field to analytics events end-to-end — schema, model, parser, renderer, tests, templates. Trigger on "/add-event-field <field_name>" or when user asks to add a field to events.
---

# Add Event Field

Add a new field across the entire stack.

## Required argument

Field name (e.g. `priority`, `category`, `version`)

## Steps

1. **Schema** — add to `schema/events.schema.json` → `$defs.event.properties`
   - Include `type`, `title`, `description`, `default` (if any), `examples`

2. **Dart model** — add to `lib/src/models/analytics_event.dart`
   - Add field, update constructor, equality, toString, copyWith

3. **Dart parser** — update `lib/src/parser/event_parser.dart`
   - Parse the new field from YAML map

4. **Dart renderer** — update `lib/src/generator/renderers/` if field affects generated code

5. **Templates** — add example to `templates/events.yaml`

6. **Tests** — add/update tests in `test/parser/` and `test/models/`

7. **Studio** — nothing needed (reads from schema dynamically)

8. **Verify** — `dart analyze`, `dart test`, `cd analytics-gen-studio && npm run build`
