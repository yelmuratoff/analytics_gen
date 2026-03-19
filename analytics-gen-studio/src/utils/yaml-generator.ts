import * as yaml from 'js-yaml';
import type { ConfigState, EventFile, SharedParamFile, ContextFile, ParamDef } from '../types/index.ts';

const DUMP_OPTIONS: yaml.DumpOptions = {
  lineWidth: -1,
  noRefs: true,
  quotingType: '"',
  forceQuotes: false,
};

function fixNullRendering(yamlStr: string): string {
  return yamlStr.replace(/: null$/gm, ':');
}

function isSimpleParam(value: ParamDef | string | null): boolean {
  if (value === null) return true;
  if (typeof value === 'string') return true;
  const keys = Object.keys(value).filter((k) => {
    const v = value[k as keyof ParamDef];
    return v !== undefined && v !== '' && !(Array.isArray(v) && v.length === 0) && !(typeof v === 'object' && v !== null && !Array.isArray(v) && Object.keys(v).length === 0);
  });
  if (keys.length === 0) return true;
  if (keys.length === 1 && keys[0] === 'type') return true;
  return false;
}

function cleanParam(value: ParamDef | string | null): unknown {
  if (value === null) return null;
  if (typeof value === 'string') return value;
  if (isSimpleParam(value) && value.type) return value.type;
  const cleaned: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(value)) {
    if (v === undefined || v === '') continue;
    if (Array.isArray(v) && v.length === 0) continue;
    if (typeof v === 'object' && v !== null && !Array.isArray(v) && Object.keys(v).length === 0) continue;
    cleaned[k] = v;
  }
  return cleaned;
}

export function generateConfigYaml(config: ConfigState): string {
  const output: Record<string, unknown> = {
    analytics_gen: {
      inputs: {
        events: config.inputs.events,
        shared_parameters: config.inputs.shared_parameters,
        contexts: config.inputs.contexts,
        imports: config.inputs.imports,
      },
      outputs: {
        dart: config.outputs.dart,
        ...(config.outputs.docs ? { docs: config.outputs.docs } : {}),
        ...(config.outputs.exports ? { exports: config.outputs.exports } : {}),
      },
      targets: { ...config.targets },
      rules: { ...config.rules },
      naming: {
        casing: config.naming.casing,
        enforce_snake_case_domains: config.naming.enforce_snake_case_domains,
        enforce_snake_case_parameters: config.naming.enforce_snake_case_parameters,
        event_name_template: config.naming.event_name_template,
        identifier_template: config.naming.identifier_template,
        domain_aliases: config.naming.domain_aliases,
      },
      meta: { ...config.meta },
    },
  };
  return yaml.dump(output, DUMP_OPTIONS);
}

function cleanEventFields(event: Record<string, unknown>): Record<string, unknown> {
  const cleaned: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(event)) {
    if (key === 'parameters') continue; // handled separately
    if (value === undefined || value === '' || value === false) continue;
    if (value === 'No description provided') continue;
    if (Array.isArray(value) && value.length === 0) continue;
    if (typeof value === 'object' && value !== null && !Array.isArray(value) && Object.keys(value).length === 0) continue;
    cleaned[key] = value;
  }
  return cleaned;
}

export function generateEventFileYaml(file: EventFile): string {
  const output: Record<string, Record<string, unknown>> = {};
  for (const [domainName, events] of Object.entries(file.domains)) {
    output[domainName] = {};
    for (const [eventName, event] of Object.entries(events)) {
      const eventOut = cleanEventFields(event as unknown as Record<string, unknown>);

      const params: Record<string, unknown> = {};
      for (const [paramName, paramValue] of Object.entries(event.parameters)) {
        params[paramName] = cleanParam(paramValue);
      }
      eventOut.parameters = params;

      output[domainName][eventName] = eventOut;
    }
  }
  return fixNullRendering(yaml.dump(output, DUMP_OPTIONS));
}

export function generateSharedParamFileYaml(file: SharedParamFile): string {
  const params: Record<string, unknown> = {};
  for (const [name, value] of Object.entries(file.parameters)) {
    params[name] = cleanParam(value);
  }
  const output = { parameters: params };
  return yaml.dump(output, DUMP_OPTIONS);
}

export function generateContextFileYaml(file: ContextFile): string {
  const props: Record<string, unknown> = {};
  for (const [name, value] of Object.entries(file.properties)) {
    props[name] = cleanParam(value);
  }
  const output = { [file.contextName]: props };
  return yaml.dump(output, DUMP_OPTIONS);
}
