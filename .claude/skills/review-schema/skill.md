---
name: review-schema
description: Review JSON schemas in schema/ for correctness, consistency, completeness. Check that schemas match Dart models, parsers, and Studio. Trigger on "/review-schema".
---

# Review Schema

Deep review of `schema/*.json` files.

## Steps

1. Read all 5 schema files in `schema/`
2. Cross-reference with Dart parser code:
   - `lib/src/parser/parameter_parser.dart` — does it handle all parameter.schema.json fields?
   - `lib/src/parser/event_parser.dart` — does it handle all events.schema.json fields?
   - `lib/src/parser/context_parser.dart` — does it handle all context.schema.json fields?
   - `lib/src/parser/shared_parameter_parser.dart` — does it handle all shared_parameters.schema.json fields?
   - `lib/src/config/config_parser.dart` — does it handle all analytics_gen.schema.json fields?
3. Cross-reference with Dart models:
   - `lib/src/models/analytics_parameter.dart` — all fields from parameter schema present?
   - `lib/src/models/analytics_event.dart` — all fields from event schema present?
   - `lib/src/config/analytics_config.dart` — all config sections present?
4. Check schema quality:
   - Every property has `title` and `description`
   - Every property has `type`
   - Defaults make sense
   - Examples are realistic
   - `x-alias-for` fields have matching originals
5. Report:
   - Fields in schema but NOT in Dart code
   - Fields in Dart code but NOT in schema
   - Missing titles/descriptions
   - Inconsistencies between schemas (e.g. parameter.schema vs events.schema parameter ref)
