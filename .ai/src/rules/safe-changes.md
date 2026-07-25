# Safe Change Rules

## Compatibility

- Treat `lib/analytics_gen.dart` exports and public interfaces as a semver-governed
  package API.
- Preserve accepted configuration aliases and `FormatException` compatibility unless
  the task includes a documented breaking release.
- Treat event identifiers, generated method names, parameter types, nullability,
  defaults, and export schemas as downstream contracts.
- Use deprecation metadata and replacement pointers for tracking-plan evolution where
  consumers need a migration window.
- Call out migration impact in README, `doc/MIGRATION_GUIDES.md`, or CHANGELOG when a
  requested change affects consumers.

## Generated Artifacts

- Change canonical schemas, scripts, renderers, or serializers before derived files.
- Inspect generated diffs for stable ordering, unchanged fingerprints when inputs are
  unchanged, and timestamp-free Studio revisions.
- Keep checked-in templates, schema reference, Studio schema copies, and generated
  TypeScript types synchronized with their sources.
- Preserve generated output paths and filenames unless the task explicitly includes a
  migration for existing users.

## Operational Scope

- Keep provider SDK dependencies out of this provider-agnostic package.
- Keep secrets, credentials, PII, and real analytics payloads out of source, fixtures,
  logs, Studio exports, and generated examples.
- Coordinate changes to GitHub Pages deployment, pub.dev publishing, schema evolution,
  or release versioning as explicit release work.
- Resolve quality-gate failures at their source and report unrelated pre-existing
  failures separately.
