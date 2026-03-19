import type { RJSFSchema } from '@rjsf/utils';

export interface LoadedSchemas {
  configSchema: RJSFSchema;
  eventsSchema: RJSFSchema;
  parameterSchema: RJSFSchema;
  sharedParametersSchema: RJSFSchema;
  contextSchema: RJSFSchema;
  rawConfigSchema: RJSFSchema;
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
  // Remove minItems from allowed_values so rjsf doesn't auto-add empty items
  if (schema.properties?.allowed_values) {
    const av = { ...(schema.properties.allowed_values as Record<string, unknown>) };
    delete av.minItems;
    schema.properties = { ...schema.properties, allowed_values: av };
  }
  return schema;
}

export async function loadSchemas(): Promise<LoadedSchemas> {
  const [rawConfig, events, parameter, sharedParameters, context] = await Promise.all([
    fetchSchema('analytics_gen.schema.json'),
    fetchSchema('events.schema.json'),
    fetchSchema('parameter.schema.json'),
    fetchSchema('shared_parameters.schema.json'),
    fetchSchema('context.schema.json'),
  ]);

  return {
    configSchema: prepareConfigSchema(rawConfig),
    eventsSchema: events,
    parameterSchema: prepareParameterSchema(parameter),
    sharedParametersSchema: sharedParameters,
    contextSchema: context,
    rawConfigSchema: rawConfig,
  };
}
