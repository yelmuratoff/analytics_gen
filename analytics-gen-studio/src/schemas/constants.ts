/** Schema-derived constants. Populated by App.tsx after schemas load.
 *  Components that need these should import from here instead of hardcoding values. */

/** Default event description from events.schema.json */
export let DEFAULT_EVENT_DESCRIPTION = 'No description provided';

/** Snake case patterns from config schema */
export let SNAKE_CASE_PARAM = /^[a-z][a-z0-9_]*$/;
export let SNAKE_CASE_DOMAIN = /^[a-z0-9_]+$/;

/** Default parameter type (first type from schema examples) */
export let DEFAULT_PARAM_TYPE = 'string';

/** All parameter types from schema */
export let PARAMETER_TYPES: string[] = ['string'];

/** Non-numeric base types — min/max don't apply to these */
export let NON_NUMERIC_TYPES = new Set(['string', 'bool', 'boolean', 'dynamic']);

/** Parameter field names extracted from schema — used in validation and yaml generation */
export let PARAM_FIELD_NAMES: string[] = [];

/** Fields with x-constraints.mutually_exclusive_with */
export let PARAM_MUTUAL_EXCLUSIONS: Array<[string, string]> = [];

/** String-only fields (from schema: min_length, max_length) */
export let STRING_ONLY_FIELDS: string[] = [];

/** Numeric-only fields (from schema: min, max) */
export let NUMERIC_ONLY_FIELDS: string[] = [];

/** Operations field name from parameter schema */
export let OPERATIONS_FIELD = 'operations';

/** Called once after schemas load to set schema-derived values */
export function applySchemaConstants(values: {
  defaultEventDescription: string;
  snakeCaseDomainPattern: RegExp;
  snakeCaseParamPattern: RegExp;
  nonNumericTypes?: string[];
  defaultParamType?: string;
  parameterTypes?: string[];
  paramFieldNames?: string[];
  paramMutualExclusions?: Array<[string, string]>;
  stringOnlyFields?: string[];
  numericOnlyFields?: string[];
  operationsField?: string;
}) {
  DEFAULT_EVENT_DESCRIPTION = values.defaultEventDescription;
  SNAKE_CASE_DOMAIN = values.snakeCaseDomainPattern;
  SNAKE_CASE_PARAM = values.snakeCaseParamPattern;
  if (values.nonNumericTypes) NON_NUMERIC_TYPES = new Set(values.nonNumericTypes);
  if (values.defaultParamType) DEFAULT_PARAM_TYPE = values.defaultParamType;
  if (values.parameterTypes) PARAMETER_TYPES = values.parameterTypes;
  if (values.paramFieldNames) PARAM_FIELD_NAMES = values.paramFieldNames;
  if (values.paramMutualExclusions) PARAM_MUTUAL_EXCLUSIONS = values.paramMutualExclusions;
  if (values.stringOnlyFields) STRING_ONLY_FIELDS = values.stringOnlyFields;
  if (values.numericOnlyFields) NUMERIC_ONLY_FIELDS = values.numericOnlyFields;
  if (values.operationsField) OPERATIONS_FIELD = values.operationsField;
}
