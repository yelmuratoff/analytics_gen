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

/** Fields with x-constraints.mutually_exclusive_with */
export let PARAM_MUTUAL_EXCLUSIONS: Array<[string, string]> = [];

/** Lowercase parameter types each field applies to (from x-constraints.supported_types) */
export let TYPE_RESTRICTED_FIELDS: Record<string, string[]> = {};

/** Operations field name from parameter schema */
export let OPERATIONS_FIELD = 'operations';

/** Called once after schemas load to set schema-derived values */
export function applySchemaConstants(values: {
  defaultEventDescription: string;
  snakeCaseDomainPattern: RegExp;
  snakeCaseParamPattern: RegExp;
  defaultParamType?: string;
  parameterTypes?: string[];
  paramMutualExclusions?: Array<[string, string]>;
  typeRestrictedFields?: Record<string, string[]>;
  operationsField?: string;
}) {
  DEFAULT_EVENT_DESCRIPTION = values.defaultEventDescription;
  SNAKE_CASE_DOMAIN = values.snakeCaseDomainPattern;
  SNAKE_CASE_PARAM = values.snakeCaseParamPattern;
  if (values.defaultParamType) DEFAULT_PARAM_TYPE = values.defaultParamType;
  if (values.parameterTypes) PARAMETER_TYPES = values.parameterTypes;
  if (values.paramMutualExclusions) PARAM_MUTUAL_EXCLUSIONS = values.paramMutualExclusions;
  if (values.typeRestrictedFields) TYPE_RESTRICTED_FIELDS = values.typeRestrictedFields;
  if (values.operationsField) OPERATIONS_FIELD = values.operationsField;
}
