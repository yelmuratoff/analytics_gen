import type { RJSFSchema } from '@rjsf/utils';
import type { ConfigState } from '../types/index.ts';

export interface LoadedSchemas {
  configSchema: RJSFSchema;
  eventsSchema: RJSFSchema;
  parameterSchema: RJSFSchema;
  sharedParametersSchema: RJSFSchema;
  contextSchema: RJSFSchema;
  rawConfigSchema: RJSFSchema;
  /** Event-level schema for RJSF (without 'parameters' — those are managed separately) */
  eventEditorSchema: RJSFSchema;
  /** Parameter type options extracted from parameter.schema.json examples */
  parameterTypes: string[];
  /** Operations extracted from parameter.schema.json operations.items.enum */
  operations: string[];
  /** Casing options extracted from config schema naming.casing.enum */
  casingOptions: string[];
  /** Default config extracted from schema defaults */
  defaultConfig: ConfigState;
}

const SCHEMA_BASE = `${import.meta.env.BASE_URL}schemas`;

async function fetchSchema(name: string): Promise<RJSFSchema> {
  const res = await fetch(`${SCHEMA_BASE}/${name}`);
  if (!res.ok) throw new Error(`Failed to load schema: ${name}`);
  return res.json();
}

function stripAliasFields(schema: RJSFSchema): RJSFSchema {
  if (!schema.properties) return schema;
  const cleaned = { ...schema };
  cleaned.properties = {};
  for (const [key, value] of Object.entries(schema.properties)) {
    const prop = value as Record<string, unknown>;
    if (prop['x-alias-for']) continue;
    cleaned.properties[key] = value;
  }
  return cleaned;
}

function prepareConfigSchema(raw: RJSFSchema): RJSFSchema {
  const inner = raw.properties?.analytics_gen as RJSFSchema;
  if (!inner) return raw;
  return stripAliasFields(inner);
}

function prepareParameterSchema(raw: RJSFSchema): RJSFSchema {
  const schema = {
    ...raw,
    additionalProperties: false,
  };
  if (schema.properties?.allowed_values) {
    const av = { ...(schema.properties.allowed_values as Record<string, unknown>) };
    delete av.minItems;
    schema.properties = { ...schema.properties, allowed_values: av };
  }
  return schema;
}

function extractEventEditorSchema(eventsSchema: RJSFSchema): RJSFSchema {
  const eventDef = eventsSchema.$defs?.event as RJSFSchema | undefined;
  if (!eventDef?.properties) return { type: 'object', properties: {} };
  const { parameters: _params, ...restProps } = eventDef.properties;
  return { type: 'object', properties: restProps };
}

function extractParameterTypes(parameterSchema: RJSFSchema): string[] {
  const typeProp = parameterSchema.properties?.type as Record<string, unknown> | undefined;
  const examples = (typeProp?.examples as string[]) ?? [];
  if (examples.length === 0) return ['string', 'string?'];
  const withNullable = examples.flatMap((t) => [t, `${t}?`]);
  return [...new Set(withNullable)];
}

function extractOperations(parameterSchema: RJSFSchema): string[] {
  const opsProp = parameterSchema.properties?.operations as Record<string, unknown> | undefined;
  const items = opsProp?.items as Record<string, unknown> | undefined;
  return (items?.enum as string[]) ?? [];
}

function extractCasingOptions(configSchema: RJSFSchema): string[] {
  const naming = configSchema.properties?.naming as RJSFSchema | undefined;
  const casing = naming?.properties?.casing as Record<string, unknown> | undefined;
  return (casing?.enum as string[]) ?? [];
}

/** Recursively extract `default` values from a JSON Schema object into a plain object */
function extractDefaults(schema: RJSFSchema): Record<string, unknown> {
  const result: Record<string, unknown> = {};
  if (!schema.properties) return result;
  for (const [key, prop] of Object.entries(schema.properties)) {
    const p = prop as Record<string, unknown>;
    if (p.type === 'object' && p.properties) {
      result[key] = extractDefaults(p as RJSFSchema);
    } else if ('default' in p) {
      result[key] = p.default;
    } else if (p.type === 'array') {
      result[key] = [];
    } else if (p.type === 'string') {
      result[key] = '';
    } else if (p.type === 'boolean') {
      result[key] = false;
    } else if (p.type === 'object') {
      result[key] = {};
    }
  }
  return result;
}

function extractDefaultConfig(configSchema: RJSFSchema): ConfigState {
  return extractDefaults(configSchema) as unknown as ConfigState;
}

export async function loadSchemas(): Promise<LoadedSchemas> {
  const [rawConfig, events, parameter, sharedParameters, context] = await Promise.all([
    fetchSchema('analytics_gen.schema.json'),
    fetchSchema('events.schema.json'),
    fetchSchema('parameter.schema.json'),
    fetchSchema('shared_parameters.schema.json'),
    fetchSchema('context.schema.json'),
  ]);

  const configSchema = prepareConfigSchema(rawConfig);

  return {
    configSchema,
    eventsSchema: events,
    parameterSchema: prepareParameterSchema(parameter),
    sharedParametersSchema: sharedParameters,
    contextSchema: context,
    rawConfigSchema: rawConfig,
    eventEditorSchema: extractEventEditorSchema(events),
    parameterTypes: extractParameterTypes(parameter),
    operations: extractOperations(parameter),
    casingOptions: extractCasingOptions(configSchema),
    defaultConfig: extractDefaultConfig(configSchema),
  };
}
