// Auto-generated from JSON schemas — do not edit manually.
// Run: npm run generate-types
//
// Source schemas: public/schemas/*.schema.json
// If you change a schema, re-run this script.

// ── Config (analytics_gen.schema.json) ──

/**
 * Path to directory containing YAML event files (relative to project root).
 */
export type EventsPath = string;
/**
 * List of paths to shared parameter definition files.
 */
export type SharedParametersPaths = string[];
/**
 * List of paths to context definition files (user properties, theme, etc.).
 */
export type ContextPaths = string[];
/**
 * List of custom Dart import URIs to include in generated files.
 */
export type CustomImports = string[];
/**
 * Path where generated Dart code will be written (relative to project root).
 */
export type DartOutputPath = string;
/**
 * Path where documentation will be generated (optional). Required when generate_docs target is enabled.
 */
export type DocumentationOutputPath = string;
/**
 * Path where database exports (CSV, JSON, SQL) will be generated (optional). Required when CSV/JSON/SQL targets are enabled.
 */
export type ExportsOutputPath = string;
/**
 * Whether to generate CSV export of events and parameters.
 */
export type GenerateCSV = boolean;
/**
 * Whether to generate JSON export of events and parameters.
 */
export type GenerateJSON = boolean;
/**
 * Whether to generate SQL export (e.g., BigQuery schema).
 */
export type GenerateSQL = boolean;
/**
 * Whether to generate Markdown documentation from event definitions.
 */
export type GenerateDocumentation = boolean;
/**
 * Whether to include the runtime tracking plan in generated Dart code.
 */
export type GenerateTrackingPlan = boolean;
/**
 * Whether to generate test matchers for `package:test` to verify analytics calls in tests.
 */
export type GenerateTestMatchers = boolean;
/**
 * Whether to include the event 'description' field as a parameter in the generated analytics map.
 */
export type IncludeEventDescription = boolean;
/**
 * Whether to treat string interpolation characters ('{', '}') in event names as an error. Prevents high-cardinality dynamic event names.
 */
export type StrictEventNames = boolean;
/**
 * Whether to enforce that ALL parameters must be defined in shared parameter files. Inline parameter definitions in events will cause an error.
 */
export type EnforceCentrallyDefinedParameters = boolean;
/**
 * Whether to prevent defining parameters in events that already exist in shared parameter files. Forces use of the shared version.
 */
export type PreventEventParameterDuplicates = boolean;
/**
 * The naming convention applied to generated event names.
 */
export type EventNameCasing = 'snake_case' | 'title_case' | 'original';
/**
 * Whether to validate that domain keys are snake_case (pattern: ^[a-z0-9_]+$).
 */
export type EnforceSnakeCaseDomains = boolean;
/**
 * Whether to validate that parameter identifiers are snake_case (pattern: ^[a-z][a-z0-9_]*$).
 */
export type EnforceSnakeCaseParameters = boolean;
/**
 * Template for generating event names. Supports placeholders: {domain}, {domain_alias}, {event}.
 */
export type EventNameTemplate = string;
/**
 * Template for generating canonical event identifiers (used for uniqueness checks). Supports the same placeholders as event_name_template.
 */
export type IdentifierTemplate = string;
/**
 * Whether to automatically track event creation dates via a ledger file. Records when each event was first seen.
 */
export type AutoTrackCreationDate = boolean;
/**
 * Whether to include event meta fields (added_in, deprecated_in, etc.) in the generated event parameters map.
 */
export type IncludeMetaInParameters = boolean;
/**
 * Flat alias for inputs.events. If both are set, inputs.events takes precedence.
 */
export type EventsPathFlatAlias = string;
/**
 * Flat alias for inputs.shared_parameters.
 */
export type SharedParametersFlatAlias = string[];
/**
 * Flat alias for inputs.contexts.
 */
export type ContextsFlatAlias = string[];
/**
 * Flat alias for inputs.imports.
 */
export type ImportsFlatAlias = string[];
/**
 * Flat alias for outputs.dart.
 */
export type OutputPathFlatAlias = string;
/**
 * Flat alias for outputs.docs.
 */
export type DocsPathFlatAlias = string;
/**
 * Flat alias for outputs.exports.
 */
export type ExportsPathFlatAlias = string;
/**
 * Flat alias for targets.csv.
 */
export type GenerateCSVFlatAlias = boolean;
/**
 * Flat alias for targets.json.
 */
export type GenerateJSONFlatAlias = boolean;
/**
 * Flat alias for targets.sql.
 */
export type GenerateSQLFlatAlias = boolean;
/**
 * Flat alias for targets.docs.
 */
export type GenerateDocsFlatAlias = boolean;
/**
 * Flat alias for targets.plan.
 */
export type GeneratePlanFlatAlias = boolean;
/**
 * Flat alias for targets.test_matchers.
 */
export type GenerateTestMatchersFlatAlias = boolean;
/**
 * Flat alias for rules.include_event_description.
 */
export type IncludeEventDescriptionFlatAlias = boolean;
/**
 * Flat alias for rules.strict_event_names.
 */
export type StrictEventNamesFlatAlias = boolean;
/**
 * Flat alias for rules.enforce_centrally_defined_parameters.
 */
export type EnforceCentrallyDefinedParametersFlatAlias = boolean;
/**
 * Flat alias for rules.prevent_event_parameter_duplicates.
 */
export type PreventEventParameterDuplicatesFlatAlias = boolean;

/**
 * Main configuration file for analytics_gen code generator. Defines inputs, outputs, targets, rules, naming strategy, and meta field injection settings.
 */
export interface AnalyticsGenConfiguration {
  analytics_gen: AnalyticsGenRoot;
}
/**
 * Root configuration object. All settings are nested under this key.
 */
export interface AnalyticsGenRoot {
  inputs?: InputConfiguration;
  outputs?: OutputConfiguration;
  targets?: GenerationTargets;
  rules?: ValidationGenerationRules;
  naming?: NamingStrategy;
  meta?: MetaConfiguration;
  events_path?: EventsPathFlatAlias;
  shared_parameters?: SharedParametersFlatAlias;
  contexts?: ContextsFlatAlias;
  imports?: ImportsFlatAlias;
  output_path?: OutputPathFlatAlias;
  docs_path?: DocsPathFlatAlias;
  exports_path?: ExportsPathFlatAlias;
  generate_csv?: GenerateCSVFlatAlias;
  generate_json?: GenerateJSONFlatAlias;
  generate_sql?: GenerateSQLFlatAlias;
  generate_docs?: GenerateDocsFlatAlias;
  generate_plan?: GeneratePlanFlatAlias;
  generate_test_matchers?: GenerateTestMatchersFlatAlias;
  include_event_description?: IncludeEventDescriptionFlatAlias;
  strict_event_names?: StrictEventNamesFlatAlias;
  enforce_centrally_defined_parameters?: EnforceCentrallyDefinedParametersFlatAlias;
  prevent_event_parameter_duplicates?: PreventEventParameterDuplicatesFlatAlias;
}
/**
 * Configures where analytics_gen reads its source YAML files.
 */
export interface InputConfiguration {
  events?: EventsPath;
  shared_parameters?: SharedParametersPaths;
  contexts?: ContextPaths;
  imports?: CustomImports;
}
/**
 * Configures where analytics_gen writes generated files.
 */
export interface OutputConfiguration {
  dart?: DartOutputPath;
  docs?: DocumentationOutputPath;
  exports?: ExportsOutputPath;
}
/**
 * Toggles for which output artifacts to generate.
 */
export interface GenerationTargets {
  csv?: GenerateCSV;
  json?: GenerateJSON;
  sql?: GenerateSQL;
  docs?: GenerateDocumentation;
  plan?: GenerateTrackingPlan;
  test_matchers?: GenerateTestMatchers;
}
/**
 * Rules that control validation strictness and generation behavior.
 */
export interface ValidationGenerationRules {
  include_event_description?: IncludeEventDescription;
  strict_event_names?: StrictEventNames;
  enforce_centrally_defined_parameters?: EnforceCentrallyDefinedParameters;
  prevent_event_parameter_duplicates?: PreventEventParameterDuplicates;
}
/**
 * Controls how domains, events, and parameters are named in generated code and analytics output.
 */
export interface NamingStrategy {
  casing?: EventNameCasing;
  enforce_snake_case_domains?: EnforceSnakeCaseDomains;
  enforce_snake_case_parameters?: EnforceSnakeCaseParameters;
  event_name_template?: EventNameTemplate;
  identifier_template?: IdentifierTemplate;
  domain_aliases?: DomainAliases;
}
/**
 * Map of domain name to alias. When present, {domain_alias} in templates resolves to the mapped value instead of the domain name.
 */
export interface DomainAliases {
  [k: string]: string;
}
/**
 * Configuration for automatic meta field injection into generated events.
 */
export interface MetaConfiguration {
  auto_tracking_creation_date?: AutoTrackCreationDate;
  include_meta_in_parameters?: IncludeMetaInParameters;
}


// ── Parameter (parameter.schema.json) ──

/**
 * The data type of the parameter. Supports Dart primitive types and type aliases.
 */
export type ParameterType = string;
/**
 * Human-readable description of the parameter's purpose.
 */
export type Description = string;
/**
 * Override the Dart code identifier (method parameter name). Defaults to the YAML key name. Must be valid snake_case when enforce_snake_case_parameters is enabled.
 */
export type CodeIdentifier = string;
/**
 * Override the analytics key sent to providers. Defaults to the YAML key name.
 */
export type WireName = string;
/**
 * Explicitly set the Dart type (e.g., a custom enum type). The generator will use this type in the method signature and serialize it using `.name`. Cannot be combined with allowed_values.
 */
export type DartTypeOverride = string;
/**
 * Custom import path for the dart_type. Required when dart_type references a type from another package or file.
 */
export type DartImportPath = string;
/**
 * Restricts the parameter to a fixed set of values. The list type must match the parameter type. Cannot be combined with dart_type.
 *
 * @minItems 1
 */
export type AllowedValues = unknown[];
/**
 * Regex pattern for validation. Used in generated code for runtime validation. Cannot contain triple quotes (''').
 */
export type RegexPattern = string;
/**
 * Minimum length for string parameters.
 */
export type MinimumLength = number;
/**
 * Maximum length for string parameters.
 */
export type MaximumLength = number;
/**
 * Minimum value for numeric parameters (int, double, num).
 */
export type MinimumValue = number;
/**
 * Maximum value for numeric parameters (int, double, num).
 */
export type MaximumValue = number;
/**
 * List of operations supported by this parameter. Only used for context properties (user properties, etc.).
 */
export type Operations = ('set' | 'increment' | 'append' | 'remove')[];
/**
 * Version when this parameter was added. Used for documentation and tracking.
 */
export type AddedInVersion = string;
/**
 * Version when this parameter was deprecated. Used for documentation and tracking.
 */
export type DeprecatedInVersion = string;

/**
 * Defines a single analytics event parameter with type, validation rules, and metadata.
 */
export interface AnalyticsParameter {
  type?: ParameterType;
  description?: Description;
  identifier?: CodeIdentifier;
  param_name?: WireName;
  dart_type?: DartTypeOverride;
  import?: DartImportPath;
  allowed_values?: AllowedValues;
  regex?: RegexPattern;
  min_length?: MinimumLength;
  max_length?: MaximumLength;
  min?: MinimumValue;
  max?: MaximumValue;
  meta?: Metadata;
  operations?: Operations;
  added_in?: AddedInVersion;
  deprecated_in?: DeprecatedInVersion;
  [k: string]: unknown;
}
/**
 * Custom metadata for this parameter (e.g., ownership, Jira tickets, team).
 */
export interface Metadata {
  [k: string]: unknown;
}

