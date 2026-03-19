import { describe, it, expect, vi, beforeEach } from 'vitest';

// Mock fetch for schema loading tests
const mockSchemas = {
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

beforeEach(() => {
  vi.stubGlobal('fetch', vi.fn((url: string) => {
    const name = url.split('/').pop()!;
    const schema = mockSchemas[name as keyof typeof mockSchemas];
    if (!schema) return Promise.resolve({ ok: false, status: 404 });
    return Promise.resolve({ ok: true, json: () => Promise.resolve(schema) });
  }));
});

describe('loadSchemas', () => {
  it('loads and transforms all schemas', async () => {
    const { loadSchemas } = await import('../../schemas/loader.ts');
    const schemas = await loadSchemas();

    expect(schemas.configSchema).toBeDefined();
    expect(schemas.eventsSchema).toBeDefined();
    expect(schemas.parameterSchema).toBeDefined();
    expect(schemas.sharedParametersSchema).toBeDefined();
    expect(schemas.contextSchema).toBeDefined();
  });

  it('strips x-alias-for fields from config schema', async () => {
    const { loadSchemas } = await import('../../schemas/loader.ts');
    const schemas = await loadSchemas();

    // Config schema should be unwrapped from analytics_gen root
    // and should NOT contain alias fields
    expect(schemas.configSchema.properties).toBeDefined();
    expect(schemas.configSchema.properties!.events_path).toBeUndefined();
    expect(schemas.configSchema.properties!.generate_csv).toBeUndefined();
    // But should keep non-alias fields
    expect(schemas.configSchema.properties!.inputs).toBeDefined();
  });

  it('removes minItems from allowed_values in parameter schema', async () => {
    const { loadSchemas } = await import('../../schemas/loader.ts');
    const schemas = await loadSchemas();

    const av = schemas.parameterSchema.properties?.allowed_values as any;
    expect(av).toBeDefined();
    expect(av.minItems).toBeUndefined();
  });

  it('sets additionalProperties to false on parameter schema', async () => {
    const { loadSchemas } = await import('../../schemas/loader.ts');
    const schemas = await loadSchemas();
    expect(schemas.parameterSchema.additionalProperties).toBe(false);
  });
});
