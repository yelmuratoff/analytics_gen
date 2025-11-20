# Validation & Naming

`analytics_gen` treats the tracking plan as production code. Parsing fails fast, generated files stay deterministic, and CI can block regressions before they land. This document explains the schema, common validation errors, and how to troubleshoot them.

## Command Reference

| Command | Purpose |
| --- | --- |
| `dart run analytics_gen:generate --validate-only` | Parse every YAML file without writing outputs. Use in CI pre-checks. |
| `dart run analytics_gen:generate --plan` | Print the parsed plan: domains, events, parameters, fingerprint. Great for debugging. |
| `dart run analytics_gen:generate --docs --exports` | Generate code, docs, and external exports with the deterministic fingerprint. |

## YAML Schema Cheatsheet

```yaml
domain_name:
  event_name:
    description: Human readable details
    deprecated: false              # Optional, mark deprecated events
    replacement: auth.login_v2     # Optional pointer when deprecated
    event_name: "Screen: {name}"   # Optional override sent to providers
    identifier: auth: login        # Optional canonical identifier
    parameters:
      param_key:
        type: string               # Types: string, int, double, bool, map, list, custom
        description: Why this matters
        identifier: userId         # Override generated Dart parameter
        param_name: user-id        # Override provider payload key
        allowed_values: [card, paypal]
```

### Accepted Types

The generator maps YAML primitive names to Dart types. Prefer lower-case primitives in your plan for consistency.

| YAML Type | Dart Type | Notes |
| :--- | :--- | :--- |
| `string` | `String` | |
| `int` | `int` | |
| `double` | `double` | |
| `bool` | `bool` | |
| `list` | `List<dynamic>` | Use `list<String>` etc. if supported by your provider adapter. |
| `map` | `Map<String, dynamic>` | |
| `DateTime` | `DateTime` | Custom types pass through as-is. |

**Nullable parameters**: Append `?` to the type (e.g., `string?`, `int?`).

Rules of thumb:

- `parameters` must be a map (use `{}` when none).
- Nullable parameters append `?` (e.g., `string?`).
- Custom types (like `DateTime`) pass through directly; ensure your providers can handle them.

## Naming Strategy

Configured under `analytics_gen.naming`:

- `enforce_snake_case_domains` / `enforce_snake_case_parameters`: keep filesystem-safe keys and predictable Dart APIs. Disable only for legacy plans.
- `event_name_template` and `identifier_template`: control the canonical strings when an event omits overrides.
- `domain_aliases`: map snake_case domains to human-friendly labels for doc/export placeholders.

**Uniqueness enforcement** is performed on the resolved identifier (override > template). Duplicate identifiers abort generation so no two YAML entries can emit the same analytics payload.

### Migrating from legacy naming

Many teams inherit plans with camelCase or kebab-case. Recommended path:

1. **Freeze identifiers** – set `identifier_template` (or per-event `identifier`) to the legacy strings so analytics payloads stay stable.
2. **Disable enforcement temporarily** – set `enforce_snake_case_*: false` so the parser ingests existing YAML without blocking.
3. **Normalize domain-by-domain** – pick a domain (`marketingLaunch` → `marketing_launch`), rename the YAML key, and update `identifier` only if the canonical string should change. Regenerate + review artifacts each time.
4. **Re-enable enforcement** – once every domain/parameter follows snake_case, flip the flags back to `true` to prevent regressions.

Document the migration in `analytics_gen.yaml` comments or README so future contributors know why the temporary relaxation existed.

## Placeholder Interpolation

Placeholders declared in `event_name` (`"Screen: {screen_name}"`) map to generated Dart variables:

```dart
logger.logEvent(
  name: "Screen: ${screenName}",
  parameters: {
    "screen_name": screenName,
    if (previousScreen != null) "previous_screen": previousScreen,
  },
);
```

- Placeholder keys must match YAML parameter names exactly.
- Unknown placeholders stay as-is; this keeps the YAML explicit and predictable.

## Common Validation Errors

| Error | Why it happens | Fix |
| --- | --- | --- |
| `Domain "Auth" ... violates the configured naming strategy` | Domain keys must satisfy the configured casing rules. | Rename to `auth` or set `enforce_snake_case_domains: false`. |
| `Parameter identifier "userId" ... violates the configured naming strategy` | Parameter identifiers default to snake_case. | Use `identifier: userId` to expose camelCase in Dart or relax enforcement globally. |
| `Duplicate analytics event identifier` | Two events resolve to the same canonical identifier. | Provide unique `identifier` values or adjust the template. |
| `Parameters ... must be a map` | YAML indentation/structure is invalid. | Ensure `parameters` points to a map (use `{}` when there are no parameters). |
| `Allowed values must be a non-empty list` | `allowed_values` was empty or not a list. | Provide at least one allowed value or remove the guard. |

CI should call `--validate-only` to catch these failures without touching generated files.

## Runtime Guards

- `allowed_values` produces runtime assertions in generated methods. Passing a disallowed value throws `ArgumentError` immediately, making mistakes obvious in tests.
- Deprecated events include their replacement in generated documentation and mixin comments so you can migrate safely.
- Custom types (e.g., `DateTime`, `Uri`) pass through unchanged. Ensure your providers can serialize them; otherwise, transform to primitives before logging (e.g., convert `DateTime` to ISO 8601 strings). Add unit tests exercising provider adapters so unsupported types fail fast instead of silently dropping data.

## Deterministic Outputs

YAML files, domains, and events are sorted before emission. Docs, JSON, SQL, and SQLite exports embed a fingerprint derived from the plan content (no timestamps). Byte-for-byte consistency keeps PR diffs reviewable, and you can safely re-run generation locally or in CI without noisy churn.

## Troubleshooting Checklist

1. Run `--plan` to inspect the parsed structure.
2. Confirm naming strategy values in `analytics_gen.yaml`.
3. Search for duplicate `identifier` strings across the plan (`rg "identifier:" events`).
4. Re-run `--validate-only` before generating code to ensure errors are resolved.

Still confused? Pair this doc with the [Onboarding Guide](./ONBOARDING.md) and share plan context in PR descriptions so reviewers can spot issues faster.
