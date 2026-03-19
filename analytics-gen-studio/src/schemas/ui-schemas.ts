import type { UiSchema } from '@rjsf/utils';

// Use lowercase 'checkbox' so FieldTemplate recognizes it and skips duplicate description
const checkbox = { 'ui:widget': 'checkbox' };

// Note: configUiSchema is no longer needed — ConfigTab renders dynamically from schema.

export const eventEditorUiSchema: UiSchema = {
  description: {
    'ui:widget': 'textarea',
    'ui:options': { rows: 3 },
    'ui:placeholder': 'Describe when this event should be fired',
  },
  deprecated: checkbox,
  meta: {
    'ui:widget': 'textarea',
    'ui:options': { rows: 3 },
    'ui:placeholder': '{"owner": "team", "jira": "PROJ-123"}',
  },
  dual_write_to: {
    'ui:options': { addable: true, orderable: false, removable: true },
  },
};

export const parameterEditorUiSchema: UiSchema = {
  description: {
    'ui:widget': 'textarea',
    'ui:options': { rows: 2 },
  },
  allowed_values: {
    'ui:options': { addable: true, orderable: false, removable: true },
  },
  operations: {
    'ui:widget': 'checkboxes',
    'ui:options': { inline: true },
  },
};
