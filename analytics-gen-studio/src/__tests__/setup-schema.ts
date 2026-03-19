// Runs after setup.ts (localStorage is available)
// Applies schema-derived defaults so tests work with real values

import { setSchemaDefaultConfig } from '../state/store.ts';
import { applySchemaConstants } from '../schemas/constants.ts';
import type { ConfigState } from '../types/index.ts';

applySchemaConstants({
  defaultEventDescription: 'No description provided',
  snakeCaseDomainPattern: /^[a-z0-9_]+$/,
  snakeCaseParamPattern: /^[a-z][a-z0-9_]*$/,
});

const testDefaults: ConfigState = {
  inputs: { events: 'events', shared_parameters: [], contexts: [], imports: [] },
  outputs: { dart: 'lib/src/analytics/generated' },
  targets: { csv: false, json: false, sql: false, docs: false, plan: true, test_matchers: false },
  rules: { include_event_description: false, strict_event_names: true, enforce_centrally_defined_parameters: false, prevent_event_parameter_duplicates: false },
  naming: { casing: 'snake_case', enforce_snake_case_domains: true, enforce_snake_case_parameters: true, event_name_template: '{domain}: {event}', identifier_template: '{domain}: {event}', domain_aliases: {} },
  meta: { auto_tracking_creation_date: false, include_meta_in_parameters: false },
};
setSchemaDefaultConfig(testDefaults);
