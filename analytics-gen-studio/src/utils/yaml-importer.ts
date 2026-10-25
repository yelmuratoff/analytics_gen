import * as yaml from 'js-yaml';
import type { RJSFSchema } from '@rjsf/utils';
import type { EventFile, SharedParamFile, ContextFile, ConfigState, EventDef, ParamDef, TabId } from '../types/index.ts';

export type YamlFileType = 'config' | 'events' | 'shared' | 'context';

export interface ImportSchemaHints {
  /** Root key name from config schema (e.g. "analytics_gen") */
  configRootKey: string;
  /** Root key name from shared params schema (e.g. "parameters") */
  sharedRootKey: string;
  /** Event-level field names from events schema $defs.event */
  eventFieldNames: string[];
  /** Config sections nested under the root key (e.g. "inputs") */
  configSections: string[];
  /** Flat config keys mapped to the "section.field" they alias, from x-alias-for */
  configAliases: Record<string, string>;
}

/** Extract detection hints from loaded schemas — no hardcoded values */
export function extractImportHints(
  rawConfigSchema: RJSFSchema,
  eventsSchema: RJSFSchema,
  sharedSchema: RJSFSchema,
): ImportSchemaHints {
  // Config root key: the single property in the config schema
  const configKeys = Object.keys(rawConfigSchema.properties ?? {});
  const configRootKey = configKeys[0] ?? 'analytics_gen';

  // Shared root key: the single property in the shared params schema
  const sharedKeys = Object.keys(sharedSchema.properties ?? {});
  const sharedRootKey = sharedKeys[0] ?? 'parameters';

  // Event field names from $defs.event
  const eventDef = (eventsSchema.$defs?.event ?? eventsSchema.$defs?.Event) as RJSFSchema | undefined;
  const eventFieldNames = Object.keys(eventDef?.properties ?? {});

  const configRoot = rawConfigSchema.properties?.[configRootKey] as RJSFSchema | undefined;
  const configSections: string[] = [];
  const configAliases: Record<string, string> = {};
  for (const [key, value] of Object.entries(configRoot?.properties ?? {})) {
    const property = value as Record<string, unknown>;
    if (typeof property['x-alias-for'] === 'string') configAliases[key] = property['x-alias-for'];
    else if (property.type === 'object') configSections.push(key);
  }

  return { configRootKey, sharedRootKey, eventFieldNames, configSections, configAliases };
}

/** Detect YAML file type using schema-derived hints */
export function detectYamlType(
  data: Record<string, unknown>,
  hints: ImportSchemaHints,
): YamlFileType | null {
  const keys = Object.keys(data);
  if (keys.length === 0) return null;

  // Config: has the config root key
  if (keys.length === 1 && keys[0] === hints.configRootKey) return 'config';

  // Shared params: has the shared root key
  if (keys.length === 1 && keys[0] === hints.sharedRootKey) return 'shared';

  // Context vs Events: both have arbitrary root keys
  // Context: exactly 1 root key, value is a flat map of properties (not nested domains)
  // Events: root keys are domains, each domain contains events with known event fields
  if (keys.length === 1) {
    const value = data[keys[0]];
    if (isObject(value)) {
      // Check if it looks like a domain (events inside)
      if (looksLikeDomain(value as Record<string, unknown>, hints.eventFieldNames)) {
        return 'events';
      }
      // Otherwise it's a context (flat property map)
      return 'context';
    }
  }

  // Multiple root keys: must be events (multiple domains)
  if (keys.length > 1) {
    // Verify at least one looks like a domain
    for (const key of keys) {
      if (isObject(data[key]) && looksLikeDomain(data[key] as Record<string, unknown>, hints.eventFieldNames)) {
        return 'events';
      }
    }
  }

  return null;
}

/** Check if an object looks like a domain (contains events with known event fields) */
function looksLikeDomain(obj: Record<string, unknown>, eventFields: string[]): boolean {
  for (const value of Object.values(obj)) {
    if (!isObject(value)) continue;
    const eventObj = value as Record<string, unknown>;
    // If any nested value has known event fields, this is a domain
    if (eventFields.some((f) => f in eventObj)) return true;
  }
  return false;
}

function isObject(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null && !Array.isArray(v);
}

// ── Parsers ──

/** Normalize a raw parameter value from YAML into store format */
function normalizeParam(raw: unknown): ParamDef | string | null {
  if (raw === null || raw === undefined) return null; // shared ref
  if (typeof raw === 'string') return raw; // simple type shorthand
  if (isObject(raw)) return raw as ParamDef; // full param object
  return String(raw);
}

/** Normalize a raw event object — guarantees `parameters` is a record. */
export function normalizeEventDef(raw: unknown): EventDef | null {
  if (!isObject(raw)) return null;
  const { parameters: rawParams, ...eventFields } = raw;

  const parameters: Record<string, ParamDef | string | null> = {};
  if (isObject(rawParams)) {
    for (const [pn, pv] of Object.entries(rawParams)) {
      parameters[pn] = normalizeParam(pv);
    }
  }

  return { ...eventFields, parameters } as EventDef;
}

/** Parse a YAML event file into store EventFile */
export function parseEventYaml(data: Record<string, unknown>, fileName: string): EventFile {
  const domains: EventFile['domains'] = {};

  for (const [domainName, domainData] of Object.entries(data)) {
    if (!isObject(domainData)) continue;
    const events: Record<string, EventDef> = {};

    for (const [eventName, eventData] of Object.entries(domainData)) {
      const normalized = normalizeEventDef(eventData);
      if (normalized) events[eventName] = normalized;
    }

    domains[domainName] = events;
  }

  return { fileName, domains };
}

/** Parse a YAML shared params file into store SharedParamFile */
export function parseSharedYaml(
  data: Record<string, unknown>,
  fileName: string,
  sharedRootKey: string,
): SharedParamFile {
  const rawParams = data[sharedRootKey];
  const parameters: Record<string, ParamDef | string> = {};

  if (isObject(rawParams)) {
    for (const [pn, pv] of Object.entries(rawParams as Record<string, unknown>)) {
      const norm = normalizeParam(pv);
      parameters[pn] = norm === null ? 'string' : norm; // shared files don't have null refs
    }
  }

  return { fileName, parameters };
}

/** Parse a YAML context file into store ContextFile */
export function parseContextYaml(data: Record<string, unknown>, fileName: string): ContextFile {
  const contextName = Object.keys(data)[0];
  const rawProps = data[contextName];
  const properties: Record<string, ParamDef | string> = {};

  if (isObject(rawProps)) {
    for (const [pn, pv] of Object.entries(rawProps as Record<string, unknown>)) {
      const norm = normalizeParam(pv);
      properties[pn] = norm === null ? 'string' : norm;
    }
  }

  return { fileName, contextName, properties };
}

/**
 * Parse a YAML config file into nested config sections (partial merge).
 * Flat aliases move to the setting they alias unless the nested form also sets it;
 * keys that are neither sections nor aliases are returned as ignored.
 */
export function parseConfigYaml(
  data: Record<string, unknown>,
  hints: ImportSchemaHints,
): { config: Partial<ConfigState>; ignoredKeys: string[] } {
  const inner = data[hints.configRootKey];
  if (!isObject(inner)) return { config: {}, ignoredKeys: [] };

  const sections: Record<string, Record<string, unknown>> = {};
  const ignoredKeys: string[] = [];
  for (const [key, value] of Object.entries(inner)) {
    if (hints.configSections.includes(key) && isObject(value)) sections[key] = { ...value };
    else if (!(key in hints.configAliases)) ignoredKeys.push(key);
  }
  for (const [alias, target] of Object.entries(hints.configAliases)) {
    if (!(alias in inner)) continue;
    const [section, field] = target.split('.');
    sections[section] ??= {};
    if (!(field in sections[section])) sections[section][field] = inner[alias];
  }

  return { config: sections as Partial<ConfigState>, ignoredKeys };
}

export interface YamlImportResult {
  type: YamlFileType;
  eventFile?: EventFile;
  sharedFile?: SharedParamFile;
  contextFile?: ContextFile;
  config?: Partial<ConfigState>;
  ignoredKeys?: string[];
}

/** Parse raw YAML string, detect type, return structured result */
export function importYamlString(
  yamlContent: string,
  fileName: string,
  hints: ImportSchemaHints,
): YamlImportResult | null {
  const data = yaml.load(yamlContent);
  if (!isObject(data)) return null;
  const parsed = data as Record<string, unknown>;

  const type = detectYamlType(parsed, hints);
  if (!type) return null;

  switch (type) {
    case 'config':
      return { type, ...parseConfigYaml(parsed, hints) };
    case 'events':
      return { type, eventFile: parseEventYaml(parsed, fileName) };
    case 'shared':
      return { type, sharedFile: parseSharedYaml(parsed, fileName, hints.sharedRootKey) };
    case 'context':
      return { type, contextFile: parseContextYaml(parsed, fileName) };
  }
}

/** The editor tab that shows a file of the given type. */
export function tabForImport(type: YamlFileType): TabId {
  return type === 'context' ? 'contexts' : type;
}

export interface ImportFailure {
  fileName: string;
  reason: string;
}

export interface ImportSummary {
  imported: number;
  failures: ImportFailure[];
  ignoredKeys: string[];
}

/** One user-facing message for a batch import, naming every skipped file and ignored config key. */
export function describeImport({ imported, failures, ignoredKeys }: ImportSummary): { message: string; severity: 'success' | 'error' } {
  const parts = [`Imported ${imported} file${imported === 1 ? '' : 's'}`];
  if (failures.length > 0) {
    parts.push(`Skipped ${failures.map((f) => `${f.fileName} (${f.reason})`).join(', ')}`);
  }
  if (ignoredKeys.length > 0) {
    parts.push(`Ignored unknown config keys: ${ignoredKeys.join(', ')}`);
  }
  const clean = failures.length === 0 && ignoredKeys.length === 0;
  return { message: parts.join('. '), severity: clean ? 'success' : 'error' };
}
