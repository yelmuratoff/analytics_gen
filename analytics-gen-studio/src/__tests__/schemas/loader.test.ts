import { describe, it, expect, vi, beforeEach } from 'vitest';

const mockSchemas: Record<string, object> = {
  'analytics_gen.schema.json': {
    type: 'object',
    properties: {
      analytics_gen: {
        type: 'object',
        properties: {
          inputs: { type: 'object', properties: { events: { type: 'string' } } },
          events_path: { type: 'string', 'x-alias-for': 'inputs.events' },
          generate_csv: { type: 'boolean', 'x-alias-for': 'targets.csv' },
        },
      },
    },
  },
  'events.schema.json': { type: 'object' },
  'parameter.schema.json': {
    type: 'object',
    properties: {
      type: { type: 'string' },
      allowed_values: { type: 'array', minItems: 1, items: {} },
    },
    additionalProperties: { description: 'legacy' },
  },
  'shared_parameters.schema.json': { type: 'object' },
  'context.schema.json': { type: 'object' },
};

function mockFetch(overrides: Record<string, 'fail' | object> = {}) {
  vi.stubGlobal('fetch', vi.fn((url: string) => {
    const name = url.split('/').pop()!;
    if (overrides[name] === 'fail') return Promise.resolve({ ok: false, status: 404 });
    const schema = overrides[name] ?? mockSchemas[name];
    if (!schema) return Promise.resolve({ ok: false, status: 404 });
    return Promise.resolve({ ok: true, json: () => Promise.resolve(schema) });
  }));
}

beforeEach(() => {
  vi.resetModules();
  mockFetch();
});

describe('loadSchemas', () => {
  it('loads all 5 schemas', async () => {
    const { loadSchemas } = await import('../../schemas/loader.ts');
    const s = await loadSchemas();
    expect(s.configSchema).toBeDefined();
    expect(s.eventsSchema).toBeDefined();
    expect(s.parameterSchema).toBeDefined();
    expect(s.sharedParametersSchema).toBeDefined();
    expect(s.contextSchema).toBeDefined();
    expect(s.rawConfigSchema).toBeDefined();
  });

  it('strips x-alias-for from config schema', async () => {
    const { loadSchemas } = await import('../../schemas/loader.ts');
    const s = await loadSchemas();
    expect(s.configSchema.properties?.events_path).toBeUndefined();
    expect(s.configSchema.properties?.generate_csv).toBeUndefined();
    expect(s.configSchema.properties?.inputs).toBeDefined();
  });

  it('removes minItems from allowed_values', async () => {
    const { loadSchemas } = await import('../../schemas/loader.ts');
    const s = await loadSchemas();
    expect((s.parameterSchema.properties?.allowed_values as any)?.minItems).toBeUndefined();
    expect((s.parameterSchema.properties?.allowed_values as any)?.type).toBe('array');
  });

  it('sets additionalProperties false on parameter schema', async () => {
    const { loadSchemas } = await import('../../schemas/loader.ts');
    const s = await loadSchemas();
    expect(s.parameterSchema.additionalProperties).toBe(false);
  });

  it('rejects on fetch failure', async () => {
    mockFetch({ 'events.schema.json': 'fail' });
    const { loadSchemas } = await import('../../schemas/loader.ts');
    await expect(loadSchemas()).rejects.toThrow('Failed to load schema');
  });

  it('preserves rawConfigSchema unmodified', async () => {
    const { loadSchemas } = await import('../../schemas/loader.ts');
    const s = await loadSchemas();
    // rawConfigSchema should still have analytics_gen wrapper
    expect(s.rawConfigSchema.properties?.analytics_gen).toBeDefined();
  });
});
