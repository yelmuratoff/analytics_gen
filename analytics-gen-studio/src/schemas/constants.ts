/** Schema-derived constants. Populated by App.tsx after schemas load.
 *  Components that need these should import from here instead of hardcoding values. */

/** Default event description from events.schema.json */
export let DEFAULT_EVENT_DESCRIPTION = 'No description provided';

/** Snake case patterns from config schema */
export let SNAKE_CASE_PARAM = /^[a-z][a-z0-9_]*$/;
export let SNAKE_CASE_DOMAIN = /^[a-z0-9_]+$/;

/** Called once after schemas load to set schema-derived values */
export function applySchemaConstants(values: {
  defaultEventDescription: string;
  snakeCaseDomainPattern: RegExp;
  snakeCaseParamPattern: RegExp;
}) {
  DEFAULT_EVENT_DESCRIPTION = values.defaultEventDescription;
  SNAKE_CASE_DOMAIN = values.snakeCaseDomainPattern;
  SNAKE_CASE_PARAM = values.snakeCaseParamPattern;
}
