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
  targets: { csv: false, json: false, sql: false, docs: false, plan: true, test_matchers: false, studio: false },
  rules: { include_event_description: false, strict_event_names: true, enforce_centrally_defined_parameters: false, prevent_event_parameter_duplicates: false },
  naming: { casing: 'snake_case', enforce_snake_case_domains: true, enforce_snake_case_parameters: true, event_name_template: '{domain}: {event}', identifier_template: '{domain}: {event}', domain_aliases: {} },
  meta: { auto_tracking_creation_date: false, include_meta_in_parameters: false },
};

function eventFile(domains: EventFile['domains']): EventFile {
  return { fileName: 'test.yaml', domains };
}

describe('generateConfigYaml', () => {
  it('wraps in analytics_gen root', () => {
    expect(generateConfigYaml(defaultConfig)).toMatch(/^analytics_gen:/);
  });

  it('includes all sections', () => {
    const y = generateConfigYaml(defaultConfig);
    for (const s of ['inputs:', 'outputs:', 'targets:', 'rules:', 'naming:', 'meta:']) {
      expect(y).toContain(s);
    }
  });

  it('omits optional outputs when not set', () => {
    const y = generateConfigYaml(defaultConfig);
    const outputsSection = y.split('outputs:')[1].split('targets:')[0];
    expect(outputsSection).not.toContain('docs:');
    expect(outputsSection).not.toContain('exports:');
  });

  it('includes optional outputs when set', () => {
    const c = { ...defaultConfig, outputs: { dart: 'lib/gen', docs: 'docs/', exports: 'out/' } };
    const y = generateConfigYaml(c);
    expect(y).toContain('docs: docs/');
    expect(y).toContain('exports: out/');
  });

  it('includes domain_aliases', () => {
    const c = { ...defaultConfig, naming: { ...defaultConfig.naming, domain_aliases: { auth: 'Auth Flow' } } };
    expect(generateConfigYaml(c)).toContain('auth: Auth Flow');
  });

  it('outputs shared_parameters as array', () => {
    const c = { ...defaultConfig, inputs: { ...defaultConfig.inputs, shared_parameters: ['a.yaml', 'b.yaml'] } };
    const y = generateConfigYaml(c);
    expect(y).toContain('- a.yaml');
    expect(y).toContain('- b.yaml');
  });

  it('outputs empty arrays inline', () => {
    const y = generateConfigYaml(defaultConfig);
    expect(y).toContain('shared_parameters: []');
  });
});

describe('generateEventFileYaml', () => {
  it('generates domain/event structure', () => {
    const y = generateEventFileYaml(eventFile({ auth: { login: { description: 'User logs in', parameters: {} } } }));
    expect(y).toContain('auth:');
    expect(y).toContain('  login:');
    expect(y).toContain('description: User logs in');
  });

  it('renders shorthand params', () => {
    const y = generateEventFileYaml(eventFile({ d: { e: { parameters: { method: 'string' } } } }));
    expect(y).toContain('method: string');
  });

  it('renders null shared refs without null keyword', () => {
    const y = generateEventFileYaml(eventFile({ d: { e: { parameters: { session_id: null } } } }));
    expect(y).toContain('session_id:');
    expect(y).not.toContain('session_id: null');
  });

  it('collapses type-only param to shorthand', () => {
    const y = generateEventFileYaml(eventFile({ d: { e: { parameters: { age: { type: 'int' } } } } }));
    expect(y).toContain('age: int');
  });

  it('renders full param with description', () => {
    const y = generateEventFileYaml(eventFile({ d: { e: { parameters: { m: { type: 'string', description: 'Method' } } } } }));
    expect(y).toContain('type: string');
    expect(y).toContain('description: Method');
  });

  it('renders allowed_values', () => {
    const y = generateEventFileYaml(eventFile({ d: { e: { parameters: { m: { type: 'string', allowed_values: ['a', 'b'] } } } } }));
    expect(y).toContain('- a');
    expect(y).toContain('- b');
  });

  it('renders deprecated/replacement', () => {
    const y = generateEventFileYaml(eventFile({ d: { e: { deprecated: true, replacement: 'e_v2', parameters: {} } } }));
    expect(y).toContain('deprecated: true');
    expect(y).toContain('replacement: e_v2');
  });

  it('renders event_name, identifier, dual_write_to, meta', () => {
    const y = generateEventFileYaml(eventFile({
      d: { e: { event_name: 'Custom', identifier: 'd.e', dual_write_to: ['x'], meta: { owner: 'team' }, parameters: {} } },
    }));
    expect(y).toContain('event_name: Custom');
    expect(y).toContain('identifier: d.e');
    expect(y).toContain('- x');
    expect(y).toContain('owner: team');
  });

  it('renders added_in/deprecated_in', () => {
    const y = generateEventFileYaml(eventFile({ d: { e: { added_in: '1.0', deprecated_in: '2.0', parameters: {} } } }));
    expect(y).toContain('added_in:');
    expect(y).toContain('deprecated_in:');
  });

  it('omits default description', () => {
    const y = generateEventFileYaml(eventFile({ d: { e: { description: 'No description provided', parameters: {} } } }));
    expect(y).not.toContain('No description provided');
  });

  it('renders empty parameters as {}', () => {
    const y = generateEventFileYaml(eventFile({ d: { e: { parameters: {} } } }));
    expect(y).toContain('parameters: {}');
  });

  it('handles empty domains', () => {
    const y = generateEventFileYaml(eventFile({}));
    expect(y).toBe('{}\n');
  });

  it('renders param with identifier/param_name', () => {
    const y = generateEventFileYaml(eventFile({ d: { e: { parameters: { m: { type: 'string', identifier: 'my_id', param_name: 'my-name' } } } } }));
    expect(y).toContain('identifier: my_id');
    expect(y).toContain('param_name: my-name');
  });

  it('renders param with dart_type/import', () => {
    const y = generateEventFileYaml(eventFile({ d: { e: { parameters: { s: { dart_type: 'MyEnum', import: 'package:app/enums.dart' } } } } }));
    expect(y).toContain('dart_type: MyEnum');
    expect(y).toContain('import: package:app/enums.dart');
  });

  it('renders param with regex/min/max/min_length/max_length', () => {
    const y = generateEventFileYaml(eventFile({
      d: { e: { parameters: { p: { type: 'string', regex: '^[A-Z]+$', min_length: 1, max_length: 10 } } } },
    }));
    expect(y).toContain('regex:');
    expect(y).toContain('min_length: 1');
    expect(y).toContain('max_length: 10');
  });

  it('strips empty fields from param objects', () => {
    const y = generateEventFileYaml(eventFile({
      d: { e: { parameters: { p: { type: 'string', description: '', allowed_values: [], meta: {}, operations: [] } } } },
    }));
    // Should collapse to shorthand since all extra fields are empty
    expect(y).toContain('p: string');
  });
});

describe('generateSharedParamFileYaml', () => {
  it('wraps in parameters root', () => {
    const y = generateSharedParamFileYaml({ fileName: 's.yaml', parameters: { sid: 'string' } });
    expect(y).toMatch(/^parameters:/);
    expect(y).toContain('sid: string');
  });

  it('renders full param with allowed_values', () => {
    const y = generateSharedParamFileYaml({ fileName: 's.yaml', parameters: { p: { type: 'string', allowed_values: ['ios'] } } });
    expect(y).toContain('type: string');
    expect(y).toContain('- ios');
  });

  it('handles empty parameters', () => {
    const y = generateSharedParamFileYaml({ fileName: 's.yaml', parameters: {} });
    expect(y).toContain('parameters: {}');
  });
});

describe('generateContextFileYaml', () => {
  it('uses contextName as root', () => {
    expect(generateContextFileYaml({ fileName: 'u.yaml', contextName: 'user_props', properties: {} }))
      .toMatch(/^user_props:/);
  });

  it('renders operations', () => {
    const y = generateContextFileYaml({ fileName: 'u.yaml', contextName: 'ctx', properties: { c: { type: 'int', operations: ['set', 'increment'] } } });
    expect(y).toContain('- set');
    expect(y).toContain('- increment');
  });

  it('renders shorthand property', () => {
    const y = generateContextFileYaml({ fileName: 'u.yaml', contextName: 'ctx', properties: { uid: 'string' } });
    expect(y).toContain('uid: string');
  });

  it('handles empty properties', () => {
    const y = generateContextFileYaml({ fileName: 'u.yaml', contextName: 'ctx', properties: {} });
    expect(y).toContain('ctx: {}');
  });
});

// ── Edge cases for cleanParam / isSimpleParam ──

describe('cleanParam edge cases', () => {
  it('collapses param with empty description + empty allowed_values + empty meta to shorthand', () => {
    const y = generateEventFileYaml(eventFile({
      d: { e: { parameters: { p: { type: 'string', description: '', allowed_values: [], meta: {}, operations: [] } } } },
    }));
    expect(y).toContain('p: string');
    expect(y).not.toContain('description:');
  });

  it('keeps param as object when description is non-empty even if others empty', () => {
    const y = generateEventFileYaml(eventFile({
      d: { e: { parameters: { p: { type: 'string', description: 'Has desc', allowed_values: [], meta: {} } } } },
    }));
    expect(y).toContain('type: string');
    expect(y).toContain('description: Has desc');
  });

  it('renders added_in without deprecated flag', () => {
    const y = generateEventFileYaml(eventFile({ d: { e: { added_in: '1.0.0', parameters: {} } } }));
    expect(y).toContain('added_in:');
    expect(y).not.toContain('deprecated:');
  });

  it('renders param with only description (no type) as object', () => {
    const y = generateEventFileYaml(eventFile({
      d: { e: { parameters: { p: { description: 'Just a desc' } } } },
    }));
    expect(y).toContain('description: Just a desc');
  });

  it('renders multiple events in same domain', () => {
    const y = generateEventFileYaml(eventFile({
      auth: {
        login: { description: 'Login', parameters: { m: 'string' } },
        logout: { parameters: {} },
      },
    }));
    expect(y).toContain('login:');
    expect(y).toContain('logout:');
    expect(y).toContain('m: string');
  });

  it('renders multiple domains in same file', () => {
    const y = generateEventFileYaml(eventFile({
      auth: { login: { parameters: {} } },
      purchase: { completed: { parameters: {} } },
    }));
    expect(y).toContain('auth:');
    expect(y).toContain('purchase:');
  });
});
