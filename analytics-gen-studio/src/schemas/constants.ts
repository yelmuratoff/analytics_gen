/** Schema-derived constants. Populated by App.tsx after schemas load.
 *  Components that need these should import from here instead of hardcoding values. */

/** Default event description from events.schema.json */
export let DEFAULT_EVENT_DESCRIPTION = 'No description provided';

/** Snake case patterns from config schema */
export let SNAKE_CASE_PARAM = /^[a-z][a-z0-9_]*$/;
export let SNAKE_CASE_DOMAIN = /^[a-z0-9_]+$/;

/** Default parameter type (first type from schema examples) */
export let DEFAULT_PARAM_TYPE = 'string';

/** Non-numeric base types — min/max don't apply to these */
export let NON_NUMERIC_TYPES = new Set(['string', 'bool', 'boolean', 'dynamic']);

/** Called once after schemas load to set schema-derived values */
export function applySchemaConstants(values: {
  defaultEventDescription: string;
  snakeCaseDomainPattern: RegExp;
  snakeCaseParamPattern: RegExp;
  nonNumericTypes?: string[];
  defaultParamType?: string;
}) {
  DEFAULT_EVENT_DESCRIPTION = values.defaultEventDescription;
  SNAKE_CASE_DOMAIN = values.snakeCaseDomainPattern;
  SNAKE_CASE_PARAM = values.snakeCaseParamPattern;
  if (values.nonNumericTypes) NON_NUMERIC_TYPES = new Set(values.nonNumericTypes);
  if (values.defaultParamType) DEFAULT_PARAM_TYPE = values.defaultParamType;
}
