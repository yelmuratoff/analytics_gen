import type { UiSchema } from '@rjsf/utils';

// Use lowercase 'checkbox' so FieldTemplate recognizes it and skips duplicate description
const checkbox = { 'ui:widget': 'checkbox' };

export const configUiSchema: UiSchema = {
  'ui:order': ['inputs', 'outputs', 'targets', 'rules', 'naming', 'meta'],
  inputs: {
    'ui:order': ['events', 'shared_parameters', 'contexts', 'imports'],
    events: {
      'ui:placeholder': 'events',
    },
    shared_parameters: {
      'ui:options': {
        addable: true,
        orderable: false,
        removable: true,
      },
      items: {
        'ui:placeholder': 'path/to/shared_params.yaml',
      },
    },
    contexts: {
      'ui:options': {
        addable: true,
        orderable: false,
        removable: true,
      },
      items: {
        'ui:placeholder': 'path/to/context.yaml',
      },
    },
    imports: {
      'ui:options': {
        addable: true,
        orderable: false,
        removable: true,
      },
      items: {
        'ui:placeholder': 'package:my_app/models.dart',
      },
    },
  },
  outputs: {
    'ui:order': ['dart', 'docs', 'exports'],
    dart: {
      'ui:placeholder': 'lib/src/analytics/generated',
    },
    docs: {
      'ui:placeholder': 'docs/analytics (optional)',
    },
    exports: {
      'ui:placeholder': 'exports/analytics (optional)',
    },
  },
  targets: {
    'ui:order': ['plan', 'docs', 'csv', 'json', 'sql', 'test_matchers'],
    csv: checkbox,
    json: checkbox,
    sql: checkbox,
    docs: checkbox,
    plan: checkbox,
    test_matchers: checkbox,
  },
  rules: {
    'ui:order': ['strict_event_names', 'include_event_description', 'enforce_centrally_defined_parameters', 'prevent_event_parameter_duplicates'],
    include_event_description: checkbox,
    strict_event_names: checkbox,
    enforce_centrally_defined_parameters: checkbox,
    prevent_event_parameter_duplicates: checkbox,
  },
  naming: {
    'ui:order': ['casing', 'enforce_snake_case_domains', 'enforce_snake_case_parameters', 'event_name_template', 'identifier_template', 'domain_aliases'],
    casing: {
      'ui:widget': 'SelectWidget',
    },
    enforce_snake_case_domains: checkbox,
    enforce_snake_case_parameters: checkbox,
    event_name_template: {
      'ui:placeholder': '{domain}: {event}',
      'ui:help': 'Placeholders: {domain}, {domain_alias}, {event}',
    },
    identifier_template: {
      'ui:placeholder': '{domain}: {event}',
      'ui:help': 'Placeholders: {domain}, {domain_alias}, {event}',
    },
  },
  meta: {
    'ui:order': ['auto_tracking_creation_date', 'include_meta_in_parameters'],
    auto_tracking_creation_date: checkbox,
    include_meta_in_parameters: checkbox,
  },
};

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
