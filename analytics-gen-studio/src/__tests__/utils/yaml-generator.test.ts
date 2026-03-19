import { describe, it, expect } from 'vitest';
import {
  generateConfigYaml,
  generateEventFileYaml,
  generateSharedParamFileYaml,
  generateContextFileYaml,
} from '../../utils/yaml-generator.ts';
import type { ConfigState, EventFile, SharedParamFile, ContextFile } from '../../types/index.ts';

const defaultConfig: ConfigState = {
  inputs: { events: 'events', shared_parameters: [], contexts: [], imports: [] },
  outputs: { dart: 'lib/gen' },
  targets: { csv: false, json: false, sql: false, docs: false, plan: true, test_matchers: false },
  rules: { include_event_description: false, strict_event_names: true, enforce_centrally_defined_parameters: false, prevent_event_parameter_duplicates: false },
  naming: { casing: 'snake_case', enforce_snake_case_domains: true, enforce_snake_case_parameters: true, event_name_template: '{domain}: {event}', identifier_template: '{domain}: {event}', domain_aliases: {} },
  meta: { auto_tracking_creation_date: false, include_meta_in_parameters: false },
};

describe('generateConfigYaml', () => {
  it('wraps output in analytics_gen root', () => {
    const yaml = generateConfigYaml(defaultConfig);
    expect(yaml).toMatch(/^analytics_gen:/);
  });

  it('includes all sections', () => {
    const yaml = generateConfigYaml(defaultConfig);
    expect(yaml).toContain('inputs:');
    expect(yaml).toContain('outputs:');
    expect(yaml).toContain('targets:');
    expect(yaml).toContain('rules:');
    expect(yaml).toContain('naming:');
    expect(yaml).toContain('meta:');
  });

  it('omits optional outputs when empty', () => {
    const yaml = generateConfigYaml(defaultConfig);
    // outputs section should NOT have docs/exports keys (but targets.docs is fine)
    const outputsSection = yaml.split('outputs:')[1].split('targets:')[0];
    expect(outputsSection).not.toContain('docs:');
    expect(outputsSection).not.toContain('exports:');
  });

  it('includes optional outputs when set', () => {
    const config = { ...defaultConfig, outputs: { dart: 'lib/gen', docs: 'docs/', exports: 'out/' } };
    const yaml = generateConfigYaml(config);
    expect(yaml).toContain('docs: docs/');
    expect(yaml).toContain('exports: out/');
  });

  it('includes domain_aliases', () => {
    const config = { ...defaultConfig, naming: { ...defaultConfig.naming, domain_aliases: { auth: 'Auth Flow' } } };
    const yaml = generateConfigYaml(config);
    expect(yaml).toContain('auth: Auth Flow');
  });
});

describe('generateEventFileYaml', () => {
  it('generates domain/event structure', () => {
    const file: EventFile = {
      fileName: 'auth.yaml',
      domains: {
        auth: {
          login: { description: 'User logs in', parameters: {} },
        },
      },
    };
    const yaml = generateEventFileYaml(file);
    expect(yaml).toContain('auth:');
    expect(yaml).toContain('login:');
    expect(yaml).toContain('description: User logs in');
  });

  it('renders shorthand params as type string', () => {
    const file: EventFile = {
      fileName: 'test.yaml',
      domains: { d: { e: { parameters: { method: 'string' } } } },
    };
    const yaml = generateEventFileYaml(file);
    expect(yaml).toContain('method: string');
  });

  it('renders null shared refs without null keyword', () => {
    const file: EventFile = {
      fileName: 'test.yaml',
      domains: { d: { e: { parameters: { session_id: null } } } },
    };
    const yaml = generateEventFileYaml(file);
    expect(yaml).toContain('session_id:');
    expect(yaml).not.toContain('session_id: null');
  });

  it('collapses type-only params to shorthand', () => {
    const file: EventFile = {
      fileName: 'test.yaml',
      domains: { d: { e: { parameters: { age: { type: 'int' } } } } },
    };
    const yaml = generateEventFileYaml(file);
    expect(yaml).toContain('age: int');
  });

  it('renders full param objects when extra fields present', () => {
    const file: EventFile = {
      fileName: 'test.yaml',
      domains: {
        d: {
          e: {
            parameters: {
              method: { type: 'string', description: 'Login method', allowed_values: ['email', 'google'] },
            },
          },
        },
      },
    };
    const yaml = generateEventFileYaml(file);
    expect(yaml).toContain('type: string');
    expect(yaml).toContain('description: Login method');
    expect(yaml).toContain('email');
  });

  it('includes deprecated/replacement fields', () => {
    const file: EventFile = {
      fileName: 'test.yaml',
      domains: {
        d: {
          e: {
            deprecated: true,
            replacement: 'e_v2',
            parameters: {},
          },
        },
      },
    };
    const yaml = generateEventFileYaml(file);
    expect(yaml).toContain('deprecated: true');
    expect(yaml).toContain('replacement: e_v2');
  });

  it('includes meta, dual_write_to, event_name, identifier', () => {
    const file: EventFile = {
      fileName: 'test.yaml',
      domains: {
        d: {
          e: {
            event_name: 'Custom Name',
            identifier: 'd.e',
            dual_write_to: ['other'],
            meta: { owner: 'team' },
            parameters: {},
          },
        },
      },
    };
    const yaml = generateEventFileYaml(file);
    expect(yaml).toContain('event_name: Custom Name');
    expect(yaml).toContain('identifier: d.e');
    expect(yaml).toContain('- other');
    expect(yaml).toContain('owner: team');
  });

  it('omits default description', () => {
    const file: EventFile = {
      fileName: 'test.yaml',
      domains: { d: { e: { description: 'No description provided', parameters: {} } } },
    };
    const yaml = generateEventFileYaml(file);
    expect(yaml).not.toContain('No description provided');
  });

  it('handles empty parameters object', () => {
    const file: EventFile = {
      fileName: 'test.yaml',
      domains: { d: { e: { parameters: {} } } },
    };
    const yaml = generateEventFileYaml(file);
    expect(yaml).toContain('parameters: {}');
  });
});

describe('generateSharedParamFileYaml', () => {
  it('wraps in parameters root', () => {
    const file: SharedParamFile = { fileName: 'shared.yaml', parameters: { sid: 'string' } };
    const yaml = generateSharedParamFileYaml(file);
    expect(yaml).toMatch(/^parameters:/);
    expect(yaml).toContain('sid: string');
  });

  it('renders full param objects', () => {
    const file: SharedParamFile = {
      fileName: 'shared.yaml',
      parameters: { platform: { type: 'string', allowed_values: ['ios', 'android'] } },
    };
    const yaml = generateSharedParamFileYaml(file);
    expect(yaml).toContain('type: string');
    expect(yaml).toContain('ios');
  });
});

describe('generateContextFileYaml', () => {
  it('uses contextName as root key', () => {
    const file: ContextFile = { fileName: 'user.yaml', contextName: 'user_properties', properties: {} };
    const yaml = generateContextFileYaml(file);
    expect(yaml).toMatch(/^user_properties:/);
  });

  it('includes operations', () => {
    const file: ContextFile = {
      fileName: 'user.yaml',
      contextName: 'user_props',
      properties: { count: { type: 'int', operations: ['set', 'increment'] } },
    };
    const yaml = generateContextFileYaml(file);
    expect(yaml).toContain('operations:');
    expect(yaml).toContain('- set');
    expect(yaml).toContain('- increment');
  });
});
