# Schema Reference

> Auto-generated from `schema/*.json` — do not edit manually.  
> Run: `dart run scripts/generate_schema_docs.dart`

---

## Configuration (`analytics_gen.yaml`)

Main configuration file for analytics_gen code generator. Defines inputs, outputs, targets, rules, naming strategy, and meta field injection settings.

### Input Configuration

Configures where analytics_gen reads its source YAML files.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `events` | `string` | `"events"` | Path to directory containing YAML event files (relative to project root). |
| `shared_parameters` | `array` | `[]` | List of paths to shared parameter definition files. |
| `contexts` | `array` | `[]` | List of paths to context definition files (user properties, theme, etc.). |
| `imports` | `array` | `[]` | List of custom Dart import URIs to include in generated files. |

### Output Configuration

Configures where analytics_gen writes generated files.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `dart` | `string` | `"lib/src/analytics/generated"` | Path where generated Dart code will be written (relative to project root). |
| `docs` | `string` | — | Path where documentation will be generated (optional). Required when generate_docs target is enabled. |
| `exports` | `string` | — | Path where database exports (CSV, JSON, SQL) will be generated (optional). Required when CSV/JSON/SQL targets are enabled. |
| `studio` | `string` | `"analytics-studio.json"` | Path where the AnalyticsGen Studio project file will be written. Required when the studio target is enabled. |

### Generation Targets

Toggles for which output artifacts to generate.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `csv` | `boolean` | `false` | Whether to generate CSV export of events and parameters. |
| `json` | `boolean` | `false` | Whether to generate JSON export of events and parameters. |
| `sql` | `boolean` | `false` | Whether to generate SQL export (e.g., BigQuery schema). |
| `docs` | `boolean` | `false` | Whether to generate Markdown documentation from event definitions. |
| `plan` | `boolean` | `true` | Whether to include the runtime tracking plan in generated Dart code. |
| `test_matchers` | `boolean` | `false` | Whether to generate test matchers for `package:test` to verify analytics calls in tests. |
| `studio` | `boolean` | `false` | Whether to generate an `analytics-studio.json` project file importable by AnalyticsGen Studio. Output path is configured via `outputs.studio`. |

### Validation & Generation Rules

Rules that control validation strictness and generation behavior.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `include_event_description` | `boolean` | `false` | Whether to include the event 'description' field as a parameter in the generated analytics map. |
| `strict_event_names` | `boolean` | `true` | Whether to treat string interpolation characters ('{', '}') in event names as an error. Prevents high-cardinality dynamic event names. |
| `enforce_centrally_defined_parameters` | `boolean` | `false` | Whether to enforce that ALL parameters must be defined in shared parameter files. Inline parameter definitions in events will cause an error. |
| `prevent_event_parameter_duplicates` | `boolean` | `false` | Whether to prevent defining parameters in events that already exist in shared parameter files. Forces use of the shared version. |

### Naming Strategy

Controls how domains, events, and parameters are named in generated code and analytics output.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `casing` | `snake_case` \| `title_case` \| `original` | `"snake_case"` | The naming convention applied to generated event names. |
| `enforce_snake_case_domains` | `boolean` | `true` | Whether to validate that domain keys are snake_case (pattern: ^[a-z0-9_]+$). |
| `enforce_snake_case_parameters` | `boolean` | `true` | Whether to validate that parameter identifiers are snake_case (pattern: ^[a-z][a-z0-9_]*$). |
| `event_name_template` | `string` | `"{domain}: {event}"` | Template for generating event names. Supports placeholders: {domain}, {domain_alias}, {event}. |
| `identifier_template` | `string` | `"{domain}: {event}"` | Template for generating canonical event identifiers (used for uniqueness checks). Supports the same placeholders as event_name_template. |
| `domain_aliases` | `object` | `{}` | Map of domain name to alias. When present, {domain_alias} in templates resolves to the mapped value instead of the domain name. |

### Meta Configuration

Configuration for automatic meta field injection into generated events.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `auto_tracking_creation_date` | `boolean` | `false` | Whether to automatically track event creation dates via a ledger file. Records when each event was first seen. |
| `include_meta_in_parameters` | `boolean` | `false` | Whether to include event meta fields (added_in, deprecated_in, etc.) in the generated event parameters map. |

---

## Events

Defines analytics events organized by domains. Each YAML file contains one or more domains, each containing one or more events with their parameters.

### Event Properties

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `description` | `string` | `"No description provided"` | Human-readable description of the event's purpose and when it should be fired. |
| `event_name` | `string` | — | Override the generated event name that gets logged. If not set, the name is generated from the naming strategy template (e.g., '{domain}: {event}'). When strict_event_names is enabled, must not contain '{' or '}' interpolation characters. |
| `identifier` | `string` | — | Optional canonical identifier for the event, used for uniqueness checks. Generated from identifier_template if not set. |
| `deprecated` | `boolean` | `false` | Marks the event as deprecated. Generates @Deprecated annotation in Dart code. |
| `replacement` | `string` | — | The name of the replacement event if this event is deprecated. |
| `added_in` | `string` | — | Version when this event was added. |
| `deprecated_in` | `string` | — | Version when this event was deprecated. |
| `dual_write_to` | `array` | — | List of other event names to trigger simultaneously when this event is logged. Useful for migration periods. |
| `meta` | `object` | `{}` | Custom metadata for this event (e.g., ownership, Jira tickets, documentation links). |
| `parameters` | `object` | — | Map of parameter definitions for this event. Keys are parameter names. Values can be: a type string ('string', 'int?'), a full parameter object, or null to reference a shared parameter. |

---

## Parameter

Defines a single analytics event parameter with type, validation rules, and metadata.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `type` | `string` | — | The data type of the parameter. Supports Dart primitive types and type aliases. |
| `description` | `string` | — | Human-readable description of the parameter's purpose. |
| `identifier` | `string` | — | Override the Dart code identifier (method parameter name). Defaults to the YAML key name. Must be valid snake_case when enforce_snake_case_parameters is enabled. |
| `param_name` | `string` | — | Override the analytics key sent to providers. Defaults to the YAML key name. |
| `dart_type` | `string` | — | Explicitly set the Dart type (e.g., a custom enum type). The generator will use this type in the method signature and serialize it using `.name`. Cannot be combined with allowed_values. |
| `import` | `string` | — | Custom import path for the dart_type. Required when dart_type references a type from another package or file. |
| `allowed_values` | `array` | — | Restricts the parameter to a fixed set of values. The list type must match the parameter type. Cannot be combined with dart_type. |
| `regex` | `string` | — | Regex pattern for validation. Used in generated code for runtime validation. Cannot contain triple quotes ('''). |
| `min_length` | `integer` | — | Minimum length for string parameters. |
| `max_length` | `integer` | — | Maximum length for string parameters. |
| `min` | `number` | — | Minimum value for numeric parameters (int, double, num). |
| `max` | `number` | — | Maximum value for numeric parameters (int, double, num). |
| `meta` | `object` | `{}` | Custom metadata for this parameter (e.g., ownership, Jira tickets, team). |
| `operations` | `array` | — | List of operations supported by this parameter. Only used for context properties (user properties, etc.). |
| `added_in` | `string` | — | Version when this parameter was added. Used for documentation and tracking. |
| `deprecated_in` | `string` | — | Version when this parameter was deprecated. Used for documentation and tracking. |

---

## Context

Defines a context (e.g., user properties, theme context) with its properties and supported operations. Each file contains exactly one context as the root key.

Context properties use the same fields as [Parameter](#parameter), 
plus the `operations` field (`set`, `increment`, `append`, `remove`).

---

## Shared Parameters

Defines reusable analytics parameters that can be referenced across multiple events. Shared parameters are defined once and referenced by name (with null value) in event definitions.

Shared parameters use the same fields as [Parameter](#parameter). 
Reference them in events with a null value: `session_id:` (no value).

