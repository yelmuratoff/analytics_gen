# Architecture Rules

## Package Flow

- Keep the primary flow directed from CLI runners to pipeline orchestration, then
  loaders/parsers, immutable models, and generator or export implementations.
- Put CLI argument parsing and process exit behavior under `lib/src/cli/` or
  `lib/src/pipeline/`; keep reusable library services independent of process exit.
- Keep YAML decoding and validation under `lib/src/parser/`; pass validated models
  into generators instead of passing raw YAML maps across the boundary.
- Add generation stages through the existing task, renderer, serializer, or export
  abstractions under `lib/src/generator/`.
- Route package exports through `lib/analytics_gen.dart`; treat that barrel as the
  supported consumer surface.

## Cross-Stack Contract

- Use `schema/*.json` as the contract shared by Dart, templates, documentation, and
  `analytics-gen-studio/`.
- Keep Studio state in `analytics-gen-studio/src/state/store.ts` and invoke its
  actions from components; avoid duplicating shared editor state in component trees.
- Derive Studio form behavior from the loaded schemas and `x-ui` / `x-constraints`
  metadata where those fields already express the rule.
- Put pure Studio serialization and import/export logic under `src/utils/`, schema
  preparation under `src/schemas/`, and reusable stateful behavior under `src/hooks/`.

## Dependency Direction

- Keep `lib/src/models/` independent of CLI and Studio concerns.
- Inject filesystem, parser, loader, logger, and timing collaborators where existing
  constructors already expose seams for deterministic tests.
- Reuse `OutputManager`, renderer factories, and pipeline factories before adding a
  second path for equivalent generation behavior.
- Keep provider-specific SDKs outside the core package; implement the public analytics
  interfaces and capabilities in adapters owned by consuming applications.
