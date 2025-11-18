# Code Review Checklist

Instrumentation changes are compliance-sensitive: a typo in the tracking plan can silently break dashboards, exports, or contractual reporting. Use this checklist whenever you review PRs touching analytics files or generated artifacts.

## Pre-review

1. Ensure `dart run analytics_gen:generate --docs --exports` was executed after YAML changes (no stale diffs).
2. Confirm tests + `dart analyze` ran locally or in CI.
3. Skim the PR description for context: which domains changed, why, and whether downstream teams were notified.

## Tracking Plan & YAML

- [ ] Domain/event names stay consistent with naming strategy; overrides include justification.
- [ ] Descriptions are meaningful and updated when behavior changes.
- [ ] Parameters document types, nullability, and allowed values when applicable.
- [ ] Deprecations include `replacement` pointers and a migration plan.
- [ ] Search for duplicate `identifier` or payload collisions when renaming events.

## Generated Dart (`lib/src/analytics/generated`)

- [ ] Added/removed mixin methods match YAML changes exactly—no extra manual edits.
- [ ] Method signatures reflect types + nullability expectations.
- [ ] Allowed-value guards exist when defined.
- [ ] `Analytics.plan` metadata updated (fingerprint, totals) whenever events change.
- [ ] Capability usage remains optional (no provider-specific imports inside generated code).

## Documentation & Exports

- [ ] `docs/analytics_events.md` fingerprint matches YAML changes; table entries reflect new descriptions/status.
- [ ] CSV/JSON/SQL/SQLite artifacts only change when necessary; verify schema shifts with downstream consumers before approving.
- [ ] New docs (`docs/*.md`) include actionable guidance and link back to README.

## Runtime / Provider Changes

- [ ] New providers implement `IAnalytics`/`AnalyticsCapabilityProvider` cleanly and register required capabilities.
- [ ] `MultiProviderAnalytics` filters or failure handlers log enough context (provider name, event, parameters).
- [ ] Async adapters handle errors + await semantics correctly.
- [ ] Capabilities include clear key names and typed interfaces; fallback behavior is documented.

## Security & Compliance

- [ ] No secrets, tokens, or PII logged/committed in docs or code.
- [ ] Provider capability implementations avoid leaking raw user data into logs.
- [ ] Exports destined for stakeholders omit sensitive columns unless explicitly intended.

## When to Ask for Clarification

- Event identifiers changed without stakeholder sign-off.
- Generated docs/exports changed but YAML stayed untouched (likely missing regeneration).
- Capability additions that duplicate what a simpler provider method could do.
- Tests missing for new capability flows or provider adapters.

Keep this checklist in PR templates or link it in review comments so the entire team holds the same quality bar. Pair it with the [Onboarding](./ONBOARDING.md) and [Validation](./VALIDATION.md) guides when mentoring new contributors.
