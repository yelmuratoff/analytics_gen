---
name: analytics-gen-yaml-schema
description: "Create, update, and validate analytics_gen YAML tracking plans, including generator configuration, events, and shared parameters."
---

# Analytics Gen YAML tracking plans

Use this skill in applications consuming `analytics_gen` to create or change
tracking plans and regenerate their Dart APIs.

## Workflow

1. Read the application's `pubspec.yaml`, `analytics_gen.yaml`, existing event
   files, and shared parameter definitions. Keep the project's naming, paths,
   enabled targets, and validation rules. For a custom config path, append
   `--config path/to/config.yaml` to the commands below.
2. Resolve the installed package root from `.dart_tool/package_config.json`
   (run `dart pub get` if needed). Consult its `schema/*.json` for supported
   fields and constraints, `templates/*.yaml` for syntax, and
   `doc/SCHEMA_REFERENCE.md` for details. These are in the dependency, not
   necessarily in the application or alongside this installed skill. Match the
   installed version rather than assuming fields from the latest online docs.
3. Edit the source YAML. Preserve existing event identifiers, wire names,
   parameter types, nullability, and generated method names unless the requested
   migration changes them. Explain downstream impact before making a breaking
   change. Use `deprecated`, `replacement`, and `deprecated_in` when retaining an
   old event during a migration.
4. Run validation, then generation from the application root:

   ```bash
   dart run analytics_gen:generate --validate-only
   dart run analytics_gen:generate
   ```

   Fix reported source errors before generating. Use `--plan` separately to
   inspect the resolved tracking plan. For docs or exports, configure their
   output paths and targets first; `--docs --exports` explicitly enables them.
5. Inspect generated signatures and update affected application call sites.
   Run `dart analyze` and the application's relevant tests (`flutter test` in
   Flutter projects). Review generated diffs for unintended naming or contract
   changes. Regenerate a second time to confirm unchanged inputs produce
   unchanged outputs. Change YAML rather than editing generated Dart by hand.

## YAML conventions

- Put configuration under `analytics_gen`, using nested `inputs`, `outputs`,
  `targets`, `rules`, and `naming` sections. Declare `analytics_gen` as an
  application dependency because generated code imports its runtime API.
- Event files are maps of domain → event → event fields. A domain wrapper is
  required even when the file is named after that domain. Prefer one domain per
  file. Directory inputs scan top-level files; use `events/**/*.yaml` when
  recursive discovery is needed.
- Keep domain and parameter identifiers in snake_case under the default naming
  rules. Use `description` to say when the event fires. Use `parameters: {}`
  for events without parameters.
- Parameters accept a type string, a full object, or a null shared reference.
  Use `string`, `int`, `double`, `bool`, or other schema-supported types;
  append `?` for nullability. A blank value such as `platform:` references a
  shared definition; it does not mean `string?`.
- Shared files have a top-level `parameters` map and must be listed in
  `inputs.shared_parameters`. Under central-definition or duplicate-prevention
  rules, reuse shared definitions rather than introducing inline duplicates.
- `allowed_values` must be a non-empty list matching a supported scalar type.
  It cannot be combined with `dart_type`. The `dart_type` override uses enum
  `.name` serialization; provide `import` for an external enum. Inspect the
  generated signature before choosing a value at a call site.
- Parameter `identifier` controls the code identifier; `param_name` controls
  the provider payload key. Event `identifier` controls canonical uniqueness;
  `event_name` overrides the logged name. Preserve these distinct meanings.
- Keep event names static with the default `strict_event_names: true`; put
  variable values in parameters. Keep credentials and personal data out of
  event names, payload examples, and metadata.
- For contexts, consult `schema/context.schema.json` and `templates/context.yaml`
  and list files in `inputs.contexts`. Their root maps context names to property
  definitions; they do not use the events domain/event nesting.

## Minimal example

Create these three files in an application that depends on `analytics_gen`.

`analytics_gen.yaml`:

```yaml
analytics_gen:
  inputs:
    events: events
    shared_parameters: [shared_parameters.yaml]
  outputs:
    dart: lib/src/analytics/generated
```

`shared_parameters.yaml`:

```yaml
parameters:
  platform:
    type: string
    allowed_values: [ios, android, web]
```

`events/auth.yaml`:

```yaml
auth:
  login:
    description: Login completed successfully.
    parameters:
      platform:
      method: string
      previous_screen: string?
  logout:
    description: The current session ended.
    parameters: {}
```

Run the workflow commands above. Expect generated Dart under
`lib/src/analytics/generated`, with login and logout methods for the `auth`
domain. Read those files for the exact API before instrumenting application code.
