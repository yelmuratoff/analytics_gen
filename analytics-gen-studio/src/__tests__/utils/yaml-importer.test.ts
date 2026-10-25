import { describe, it, expect } from 'vitest';
import { extractImportHints, importYamlString, describeImport } from '../../utils/yaml-importer.ts';
import { canonicalSchema } from '../schema-fixtures.ts';

const hints = extractImportHints(
  canonicalSchema('analytics_gen.schema.json')!,
  canonicalSchema('events.schema.json')!,
  canonicalSchema('shared_parameters.schema.json')!,
);

describe('importYamlString', () => {
  it('reads an events file with domains, events and parameters', () => {
    const result = importYamlString(
      'auth:\n  login:\n    description: Login\n    parameters:\n      method: string\n      flow_id:\n',
      'auth.yaml',
      hints,
    );

    expect(result?.type).toBe('events');
    expect(result?.eventFile).toEqual({
      fileName: 'auth.yaml',
      domains: { auth: { login: { description: 'Login', parameters: { method: 'string', flow_id: null } } } },
    });
  });

  it('reads a shared parameters file', () => {
    const result = importYamlString('parameters:\n  user_id:\n    type: string\n', 'shared.yaml', hints);
    expect(result?.sharedFile).toEqual({ fileName: 'shared.yaml', parameters: { user_id: { type: 'string' } } });
  });

  it('reads a context file', () => {
    const result = importYamlString('user:\n  plan:\n    type: string\n', 'user.yaml', hints);
    expect(result?.contextFile).toEqual({ fileName: 'user.yaml', contextName: 'user', properties: { plan: { type: 'string' } } });
  });

  it('returns null when the file type cannot be detected', () => {
    expect(importYamlString('- just\n- a list\n', 'list.yaml', hints)).toBeNull();
  });

  it('moves flat config aliases to their nested settings', () => {
    const result = importYamlString(
      'analytics_gen:\n  events_path: events\n  shared_parameters: [events/shared.yaml]\n  generate_csv: true\n',
      'analytics_gen.yaml',
      hints,
    );

    expect(result?.config).toEqual({
      inputs: { events: 'events', shared_parameters: ['events/shared.yaml'] },
      targets: { csv: true },
    });
    expect(result?.ignoredKeys).toEqual([]);
  });

  it('keeps the nested setting when both it and its flat alias are present', () => {
    const result = importYamlString(
      'analytics_gen:\n  events_path: legacy\n  inputs:\n    events: events\n',
      'analytics_gen.yaml',
      hints,
    );

    expect(result?.config).toEqual({ inputs: { events: 'events' } });
  });

  it('reports config keys that are neither sections nor aliases', () => {
    const result = importYamlString('analytics_gen:\n  outputs:\n    dart: lib\n  unknown_setting: 1\n', 'analytics_gen.yaml', hints);

    expect(result?.config).toEqual({ outputs: { dart: 'lib' } });
    expect(result?.ignoredKeys).toEqual(['unknown_setting']);
  });
});

describe('describeImport', () => {
  it('reports a clean import', () => {
    expect(describeImport({ imported: 2, failures: [], ignoredKeys: [] }))
      .toEqual({ message: 'Imported 2 files', severity: 'success' });
  });

  it('names every file that could not be imported', () => {
    expect(describeImport({
      imported: 1,
      failures: [{ fileName: 'a.yaml', reason: 'bad indentation' }, { fileName: 'b.yaml', reason: 'unknown file type' }],
      ignoredKeys: [],
    })).toEqual({
      message: 'Imported 1 file. Skipped a.yaml (bad indentation), b.yaml (unknown file type)',
      severity: 'error',
    });
  });

  it('reports ignored config keys', () => {
    expect(describeImport({ imported: 1, failures: [], ignoredKeys: ['unknown_setting'] }))
      .toEqual({ message: 'Imported 1 file. Ignored unknown config keys: unknown_setting', severity: 'error' });
  });
});
