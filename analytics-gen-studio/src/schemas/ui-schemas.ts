import type { UiSchema } from '@rjsf/utils';
import type { RJSFSchema } from '@rjsf/utils';

/**
 * Generates RJSF UI schema from JSON Schema `x-ui` metadata.
 * This ensures UI hints live in the schema (SSOT), not hardcoded in Studio.
 *
 * Schema fields can define:
 *   "x-ui": { "widget": "textarea", "options": { "rows": 3 }, "placeholder": "..." }
 *
 * This function reads those hints and produces RJSF-compatible uiSchema.
 */
export function generateUiSchema(schema: RJSFSchema): UiSchema {
  const uiSchema: UiSchema = {};
  const properties = schema.properties ?? {};

  for (const [key, fieldSchema] of Object.entries(properties)) {
    const field = fieldSchema as Record<string, unknown>;
    const xUi = field['x-ui'] as Record<string, unknown> | undefined;
    if (!xUi) continue;

    const entry: Record<string, unknown> = {};

    if (xUi.widget) {
      entry['ui:widget'] = xUi.widget;
    }
    if (xUi.options) {
      entry['ui:options'] = xUi.options;
    }
    if (xUi.placeholder) {
      entry['ui:placeholder'] = xUi.placeholder;
    }

    if (Object.keys(entry).length > 0) {
      uiSchema[key] = entry;
    }
  }

  return uiSchema;
}

// Legacy exports for backwards compatibility — will be populated at runtime
// These are set by loader.ts after schemas are loaded
export let eventEditorUiSchema: UiSchema = {};
export let parameterEditorUiSchema: UiSchema = {};

export function applyUiSchemas(eventSchema: RJSFSchema, parameterSchema: RJSFSchema) {
  eventEditorUiSchema = generateUiSchema(eventSchema);
  parameterEditorUiSchema = generateUiSchema(parameterSchema);
}
