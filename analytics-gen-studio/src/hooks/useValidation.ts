import { useSyncExternalStore } from 'react';
import { useStore } from '../state/store.ts';
import type { ValidationError, ParamDef, ConfigState, EventFile, SharedParamFile, ContextFile } from '../types/index.ts';
import {
  SNAKE_CASE_PARAM,
  SNAKE_CASE_DOMAIN,
  NON_NUMERIC_TYPES,
  PARAM_MUTUAL_EXCLUSIONS,
  STRING_ONLY_FIELDS,
  NUMERIC_ONLY_FIELDS,
} from '../schemas/constants.ts';

function validateParam(paramName: string, param: ParamDef | string | null, path: string, tab: 'events' | 'shared' | 'contexts', enforceSnakeParams: boolean): ValidationError[] {
  const errors: ValidationError[] = [];

  // snake_case check on param name
  if (enforceSnakeParams && !SNAKE_CASE_PARAM.test(paramName)) {
    errors.push({ path, message: `"${paramName}" must be snake_case (a-z, 0-9, _)`, tab });
  }

  if (param === null || typeof param === 'string') return errors;

  // Mutual exclusion checks (from schema x-constraints)
  for (const [fieldA, fieldB] of PARAM_MUTUAL_EXCLUSIONS) {
    const valA = param[fieldA as keyof ParamDef];
    const valB = param[fieldB as keyof ParamDef];
    const hasA = valA !== undefined && valA !== '' && !(Array.isArray(valA) && valA.length === 0);
    const hasB = valB !== undefined && valB !== '' && !(Array.isArray(valB) && valB.length === 0);
    if (hasA && hasB) {
      errors.push({ path, message: `${fieldA} and ${fieldB} cannot be used together`, tab });
    }
  }

  // regex cannot contain triple quotes
  if (param.regex && param.regex.includes("'''")) {
    errors.push({ path, message: "regex cannot contain triple quotes (''')", tab });
  }

  const baseType = param.type?.replace(/\?$/, '');
  const isStringLike = baseType === 'string';
  const isNumericLike = baseType ? !NON_NUMERIC_TYPES.has(baseType) : false;

  // String-only fields check (from schema: fields with integer type + "length" in name)
  for (const field of STRING_ONLY_FIELDS) {
    if (param[field as keyof ParamDef] !== undefined && baseType && !isStringLike) {
      errors.push({ path, message: `${field} only applies to string type`, tab });
      break; // One message is enough for length fields
    }
  }

  // Numeric-only fields check (from schema: fields with number type)
  for (const field of NUMERIC_ONLY_FIELDS) {
    if (param[field as keyof ParamDef] !== undefined && baseType && !isNumericLike) {
      errors.push({ path, message: `${field} only applies to numeric types`, tab });
      break;
    }
  }

  // Range consistency: max >= min for any paired numeric fields
  if (param.min_length !== undefined && param.max_length !== undefined && param.max_length < param.min_length) {
    errors.push({ path, message: 'max_length must be >= min_length', tab });
  }
  if (param.min !== undefined && param.max !== undefined && param.max < param.min) {
    errors.push({ path, message: 'max must be >= min', tab });
  }

  // identifier pattern
  if (param.identifier && !SNAKE_CASE_PARAM.test(param.identifier)) {
    errors.push({ path, message: `identifier "${param.identifier}" must be snake_case`, tab });
  }

  return errors;
}

function computeValidation(config: ConfigState, eventFiles: EventFile[], sharedParamFiles: SharedParamFile[], contextFiles: ContextFile[]): ValidationError[] {
    const errors: ValidationError[] = [];
    const cfg = config as unknown as Record<string, Record<string, unknown>>;
    const enforceSnakeDomains = cfg.naming?.enforce_snake_case_domains as boolean ?? false;
    const enforceSnakeParams = cfg.naming?.enforce_snake_case_parameters as boolean ?? false;

    // Config: dart output path required
    if (!cfg.outputs?.dart) {
      errors.push({ path: 'config.outputs.dart', message: 'Dart output path is required', tab: 'config' });
    }

    // Events
    const evFileNames = new Set<string>();
    for (let fi = 0; fi < eventFiles.length; fi++) {
      const file = eventFiles[fi];
      if (!file.fileName) {
        errors.push({ path: 'events', message: 'File name cannot be empty', tab: 'events', fileIndex: fi });
        continue;
      }
      if (evFileNames.has(file.fileName)) {
        errors.push({ path: `events.${file.fileName}`, message: `Duplicate file name: ${file.fileName}`, tab: 'events', fileIndex: fi });
      }
      evFileNames.add(file.fileName);

      if (Object.keys(file.domains).length === 0) {
        errors.push({ path: `events.${file.fileName}`, message: 'File has no domains', tab: 'events', fileIndex: fi });
      }

      for (const [domainName, events] of Object.entries(file.domains)) {
        if (enforceSnakeDomains && !SNAKE_CASE_DOMAIN.test(domainName)) {
          errors.push({ path: `events.${file.fileName}.${domainName}`, message: `Domain "${domainName}" must be snake_case`, tab: 'events', fileIndex: fi, domain: domainName });
        }

        for (const [eventName, event] of Object.entries(events)) {
          const ePath = `events.${file.fileName}.${domainName}.${eventName}`;
          const nav = { fileIndex: fi, domain: domainName, event: eventName };

          // strict_event_names: custom event_name must not have { }
          const customEventName = event.event_name as string | undefined;
          if (cfg.rules?.strict_event_names && customEventName && (customEventName.includes('{') || customEventName.includes('}'))) {
            errors.push({ path: ePath, message: 'event_name cannot contain { } when strict_event_names is enabled', tab: 'events', ...nav });
          }

          for (const [paramName, paramVal] of Object.entries(event.parameters)) {
            errors.push(...validateParam(paramName, paramVal, `${ePath}.${paramName}`, 'events', enforceSnakeParams).map((e) => ({ ...e, ...nav, parameter: paramName })));
          }
        }
      }
    }

    // Shared params
    const spFileNames = new Set<string>();
    for (let fi = 0; fi < sharedParamFiles.length; fi++) {
      const file = sharedParamFiles[fi];
      if (!file.fileName) {
        errors.push({ path: 'shared', message: 'File name cannot be empty', tab: 'shared', fileIndex: fi });
        continue;
      }
      if (spFileNames.has(file.fileName)) {
        errors.push({ path: `shared.${file.fileName}`, message: `Duplicate file name: ${file.fileName}`, tab: 'shared', fileIndex: fi });
      }
      spFileNames.add(file.fileName);

      for (const [paramName, paramVal] of Object.entries(file.parameters)) {
        errors.push(...validateParam(paramName, paramVal, `shared.${file.fileName}.${paramName}`, 'shared', enforceSnakeParams).map((e) => ({ ...e, fileIndex: fi, parameter: paramName })));
      }
    }

    // Contexts
    const ctxFileNames = new Set<string>();
    for (let fi = 0; fi < contextFiles.length; fi++) {
      const file = contextFiles[fi];
      if (!file.fileName) {
        errors.push({ path: 'contexts', message: 'File name cannot be empty', tab: 'contexts', fileIndex: fi });
        continue;
      }
      if (!file.contextName) {
        errors.push({ path: `contexts.${file.fileName}`, message: 'Context name cannot be empty', tab: 'contexts', fileIndex: fi });
      }
      if (ctxFileNames.has(file.fileName)) {
        errors.push({ path: `contexts.${file.fileName}`, message: `Duplicate file name: ${file.fileName}`, tab: 'contexts', fileIndex: fi });
      }
      ctxFileNames.add(file.fileName);

      for (const [propName, propVal] of Object.entries(file.properties)) {
        errors.push(...validateParam(propName, propVal, `contexts.${file.fileName}.${propName}`, 'contexts', enforceSnakeParams).map((e) => ({ ...e, fileIndex: fi, contextProperty: propName })));
      }
    }

    return errors;
}

// ── Singleton validation store ──
// Validation is computed once and shared across all consumers (TabBar, Toolbar, YamlPreview).
// Debounced at 200ms — recomputes only when store data actually changes.

let cachedErrors: ValidationError[] = [];
const listeners = new Set<() => void>();

function emitChange() {
  for (const listener of listeners) listener();
}

let debounceTimer: ReturnType<typeof setTimeout> | undefined;

// Subscribe to the main store once (module-level side effect)
useStore.subscribe((state) => {
  clearTimeout(debounceTimer);
  debounceTimer = setTimeout(() => {
    const next = computeValidation(state.config, state.eventFiles, state.sharedParamFiles, state.contextFiles);
    // Only update if errors actually changed (avoid unnecessary re-renders)
    if (next.length !== cachedErrors.length || JSON.stringify(next) !== JSON.stringify(cachedErrors)) {
      cachedErrors = next;
      emitChange();
    }
  }, 200);
});

// Compute initial errors synchronously
cachedErrors = computeValidation(
  useStore.getState().config,
  useStore.getState().eventFiles,
  useStore.getState().sharedParamFiles,
  useStore.getState().contextFiles,
);

function subscribe(listener: () => void) {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

function getSnapshot() {
  return cachedErrors;
}

/** Shared validation hook — all consumers share one computation */
export function useValidation(): ValidationError[] {
  return useSyncExternalStore(subscribe, getSnapshot);
}
