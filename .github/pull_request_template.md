## Summary

- [ ] Clearly describe the analytics domains/events touched and why.
- [ ] Call out any docs/exports skipped on purpose (with reasoning).

## Testing

- [ ] `dart analyze`
- [ ] `dart test`
- [ ] `dart run analytics_gen:generate --docs --exports`
- [ ] Additional commands (if applicable):

## Review Checklist

- [ ] I walked through [`doc/CODE_REVIEW.md`](../doc/CODE_REVIEW.md) and verified every section that applies to this PR.
- [ ] I regenerated code/docs/exports after YAML changes and inspected the diffs.
- [ ] I confirmed provider/runtime changes include error handling + capability docs.
- [ ] README/CHANGELOG (or relevant docs) describe the user-facing impact.
- [ ] Stakeholders know about plan changes (events renamed, deprecated, or added).
