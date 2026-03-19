---
name: review-all
description: Full project review — schemas, Dart code, Studio, templates, docs. Checks everything is in sync. Trigger on "/review-all".
---

# Review All

Comprehensive sync check across the entire project.

## Steps

1. **Schema ↔ Dart models** — every schema field has a model field and vice versa
2. **Schema ↔ Dart parsers** — parsers handle all schema fields
3. **Schema ↔ Dart generators** — renderers output all model fields
4. **Schema ↔ Studio** — Studio reads from schemas dynamically (check loader.ts extractions work)
5. **Schema ↔ Templates** — `templates/*.yaml` demonstrate all schema features
6. **Schema ↔ Docs** — `doc/` documentation covers all features
7. **Schema ↔ Tests** — test coverage for all schema fields
8. **Dart analyze** — run `dart analyze` and report issues

## Output

Summary table:
```
| Area              | Status | Issues |
|-------------------|--------|--------|
| Schema ↔ Models   | ✅/⚠️  | ...    |
| Schema ↔ Parsers  | ✅/⚠️  | ...    |
| Schema ↔ Renderers| ✅/⚠️  | ...    |
| Schema ↔ Studio   | ✅/⚠️  | ...    |
| Schema ↔ Templates| ✅/⚠️  | ...    |
| Schema ↔ Tests    | ✅/⚠️  | ...    |
| dart analyze      | ✅/⚠️  | ...    |
```

Then detailed list of each issue with fix suggestions.
