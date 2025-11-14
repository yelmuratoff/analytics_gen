# TODO – `analytics_gen`

High-level focus: ship high-signal improvements raised during the last review and keep DX/tests/docs aligned as we go.

## Active Work Items

1. **Deterministic generation order**  
   - [x] Sort YAML files and domain/event iterations so code/docs/csv/sql outputs are consistent regardless of filesystem ordering.  
   - [x] Add regression tests covering deterministic ordering for code + docs (`YamlParser` + docs generator suites).  
   - [x] Document determinism expectations in README.
2. **Analytics singleton initialization guard**  
   - [x] Detect access before `initialize` and throw a descriptive error instead of a `LateInitializationError`.  
   - [x] Add tests covering both success and failure paths (`ensureAnalyticsInitialized`).
3. **SQLite export portability**  
   - [x] Detect `sqlite3` via a portable `sqlite3 --version` probe so Windows users are supported.  
   - [x] Avoid regenerating the SQL script twice when building the DB (reuse existing script when provided).  
   - [x] Extend tests to cover the new detection logic and SQL reuse.
4. **MockAnalyticsService API polish**  
   - [x] Make `getEventsByName` return `List<Map<String, Object?>>` so it matches `AnalyticsParams`.  
   - [x] Update README/test snippets that reference the helper.
5. **Markdown escaping**  
   - [x] Escape table cell content in docs generation to handle `|`, newlines, etc.  
   - [x] Cover with docs generator tests containing problematic characters.

## Process

- Keep README and example docs fresh as features change.
- Every change must land with focused unit tests (`dart test`).
- Update this TODO after completing each item (check the box + summarize work/tests/docs touched).
