---
name: "extend-generator"
description: >-
  Use this skill when adding or changing analytics_gen code generation, renderers,
  generation tasks, output targets, documentation, CSV/JSON/SQL/SQLite exports, test
  matchers, plan serialization, Studio export, or CLI generation flags—even when
  phrased as "emit this code", "add an output format", "generated files are wrong",
  "make generation deterministic", or "wire this into the pipeline".
---

# Extend Generator

Add generator behavior through the existing pipeline, task, renderer, and output
boundaries while preserving deterministic artifacts.

## Checklist

- [ ] Trace the request from CLI/config to `GenerationRequest`.
- [ ] Select the existing task, renderer, serializer, or export extension point.
- [ ] Write a failing focused test for output and error behavior.
- [ ] Implement the smallest generator change.
- [ ] Test deterministic reruns and stale-file behavior where relevant.
- [ ] Run analysis, tests, and any affected end-to-end generation.

## Steps

1. Read the entry path that enables the behavior:
   - CLI flags in `lib/src/cli/`
   - config targets in `lib/src/config/`
   - request selection in `lib/src/pipeline/generation_request.dart`
   - orchestration in `lib/src/pipeline/generation_pipeline.dart`
2. Read the closest implementation under `lib/src/generator/` and its tests. Use:
   - `tasks/` for filesystem-producing generation stages
   - `renderers/` and `sub_renderers/` for generated Dart sections
   - `serializers/` for structured plan output
   - `export/` for stakeholder export formats
   - `OutputManager` for writes and managed output behavior
3. Add a focused failing test under `test/generator/` or `test/pipeline/`. Assert the
   public artifact contract: filenames, imports, signatures, validation, escaping,
   metadata, or error context.
4. Keep domain models and parsed plans independent from output formatting. Pass typed
   `AnalyticsDomain`, `AnalyticsParameter`, `TrackingPlan`, or generation metadata
   into the implementation.
5. Preserve stable ordering of domains, events, parameters, imports, and serialized
   fields. Avoid wall-clock values in content fingerprints and Studio revisions.
6. Use scoped `Logger` instances supplied by the pipeline. Wrap failed asynchronous
   tasks without losing the original error or stack trace.
7. When adding a new target, wire all relevant layers: config/schema if configurable,
   CLI arguments if user-selectable, `GenerationRequest`, pipeline task creation,
   output implementation, docs, and tests.
8. Run the narrow test, then:

   ```sh
   dart format lib bin test
   dart analyze --fatal-infos
   dart test
   ```

9. For changes that affect real generated artifacts, run the matching example command
   from the repository root, such as
   `dart run analytics_gen:generate --docs --exports --studio`, and inspect its diff.
10. If the change also modifies schemas or Studio contracts, invoke the
    `change-schema-contract` skill and finish with `./scripts/sync.sh`.

## Gotchas

- `GenerationPipeline` runs the schema-evolution check before other tasks, then runs
  independent generation tasks concurrently; new ordering dependencies need an
  explicit design rather than list position.
- Generated Dart is public consumer code. Renamed methods, changed nullability, or
  altered validation exceptions require compatibility review.
- Output cleanup can delete stale managed files; test the exact managed directory and
  keep unrelated user files outside its ownership.
- `Analytics.plan` fingerprints and Studio `meta.revision` are expected to be stable
  when semantic inputs do not change.
- The package supports code-only, docs-only, exports-only, Studio-only, plan, validate,
  and watch modes; do not assume every request generates Dart.
