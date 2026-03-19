import { useMemo } from 'react';
import { useStore } from '../state/store.ts';
import type { ValidationError, ParamDef } from '../types/index.ts';

const SNAKE_CASE = /^[a-z][a-z0-9_]*$/;
const SNAKE_CASE_DOMAIN = /^[a-z0-9_]+$/;

function validateParam(paramName: string, param: ParamDef | string | null, path: string, tab: 'events' | 'shared' | 'contexts', enforceSnakeParams: boolean): ValidationError[] {
  const errors: ValidationError[] = [];

  // snake_case check on param name
  if (enforceSnakeParams && !SNAKE_CASE.test(paramName)) {
    errors.push({ path, message: `"${paramName}" must be snake_case (a-z, 0-9, _)`, tab });
  }

  if (param === null || typeof param === 'string') return errors;

  // dart_type vs allowed_values mutual exclusion
  if (param.dart_type && param.allowed_values && param.allowed_values.length > 0) {
    errors.push({ path, message: 'dart_type and allowed_values cannot be used together', tab });
  }

  // regex cannot contain triple quotes
  if (param.regex && param.regex.includes("'''")) {
    errors.push({ path, message: "regex cannot contain triple quotes (''')", tab });
  }

  // min_length / max_length only for strings
  if ((param.min_length !== undefined || param.max_length !== undefined) && param.type && !['string', 'string?'].includes(param.type)) {
    errors.push({ path, message: 'min_length/max_length only apply to string type', tab });
  }

  // min / max only for numbers
  if ((param.min !== undefined || param.max !== undefined) && param.type && !['int', 'int?', 'double', 'double?', 'num', 'num?', 'float', 'float?', 'number', 'number?'].includes(param.type)) {
    errors.push({ path, message: 'min/max only apply to numeric types', tab });
  }

  // max_length >= min_length
  if (param.min_length !== undefined && param.max_length !== undefined && param.max_length < param.min_length) {
    errors.push({ path, message: 'max_length must be >= min_length', tab });
  }

  // max >= min
  if (param.min !== undefined && param.max !== undefined && param.max < param.min) {
    errors.push({ path, message: 'max must be >= min', tab });
  }

  // identifier pattern
  if (param.identifier && !SNAKE_CASE.test(param.identifier)) {
    errors.push({ path, message: `identifier "${param.identifier}" must be snake_case`, tab });
  }

  return errors;
}

export function useValidation(): ValidationError[] {
  const config = useStore((s) => s.config);
  const eventFiles = useStore((s) => s.eventFiles);
  const sharedParamFiles = useStore((s) => s.sharedParamFiles);
  const contextFiles = useStore((s) => s.contextFiles);

  return useMemo(() => {
    const errors: ValidationError[] = [];
    const enforceSnakeDomains = config.naming.enforce_snake_case_domains;
    const enforceSnakeParams = config.naming.enforce_snake_case_parameters;

    // Config
    if (!config.outputs.dart) {
      errors.push({ path: 'config.outputs.dart', message: 'Dart output path is required', tab: 'config' });
    }
    // Events
    const evFileNames = new Set<string>();
    for (const file of eventFiles) {
      if (!file.fileName) {
        errors.push({ path: 'events', message: 'File name cannot be empty', tab: 'events' });
        continue;
      }
      if (evFileNames.has(file.fileName)) {
        errors.push({ path: `events.${file.fileName}`, message: `Duplicate file name: ${file.fileName}`, tab: 'events' });
      }
      evFileNames.add(file.fileName);

      if (Object.keys(file.domains).length === 0) {
        errors.push({ path: `events.${file.fileName}`, message: 'File has no domains', tab: 'events' });
      }

      for (const [domainName, events] of Object.entries(file.domains)) {
        if (enforceSnakeDomains && !SNAKE_CASE_DOMAIN.test(domainName)) {
          errors.push({ path: `events.${file.fileName}.${domainName}`, message: `Domain "${domainName}" must be snake_case`, tab: 'events' });
        }

        for (const [eventName, event] of Object.entries(events)) {
          const ePath = `events.${file.fileName}.${domainName}.${eventName}`;

          // strict_event_names: custom event_name must not have { }
          if (config.rules.strict_event_names && event.event_name && (event.event_name.includes('{') || event.event_name.includes('}'))) {
            errors.push({ path: ePath, message: 'event_name cannot contain { } when strict_event_names is enabled', tab: 'events' });
          }

          // deprecated without replacement is a warning (not blocking, but useful)
          // parameters validation
          for (const [paramName, paramVal] of Object.entries(event.parameters)) {
            errors.push(...validateParam(paramName, paramVal, `${ePath}.${paramName}`, 'events', enforceSnakeParams));
          }
        }
      }
    }

    // Shared params
    const spFileNames = new Set<string>();
    for (const file of sharedParamFiles) {
      if (!file.fileName) {
        errors.push({ path: 'shared', message: 'File name cannot be empty', tab: 'shared' });
        continue;
      }
      if (spFileNames.has(file.fileName)) {
        errors.push({ path: `shared.${file.fileName}`, message: `Duplicate file name: ${file.fileName}`, tab: 'shared' });
      }
      spFileNames.add(file.fileName);

      for (const [paramName, paramVal] of Object.entries(file.parameters)) {
        errors.push(...validateParam(paramName, paramVal, `shared.${file.fileName}.${paramName}`, 'shared', enforceSnakeParams));
      }
    }

    // Contexts
    const ctxFileNames = new Set<string>();
    for (const file of contextFiles) {
      if (!file.fileName) {
        errors.push({ path: 'contexts', message: 'File name cannot be empty', tab: 'contexts' });
        continue;
      }
      if (!file.contextName) {
        errors.push({ path: `contexts.${file.fileName}`, message: 'Context name cannot be empty', tab: 'contexts' });
      }
      if (ctxFileNames.has(file.fileName)) {
        errors.push({ path: `contexts.${file.fileName}`, message: `Duplicate file name: ${file.fileName}`, tab: 'contexts' });
      }
      ctxFileNames.add(file.fileName);

      for (const [propName, propVal] of Object.entries(file.properties)) {
        errors.push(...validateParam(propName, propVal, `contexts.${file.fileName}.${propName}`, 'contexts', enforceSnakeParams));
      }
    }

    return errors;
  }, [config, eventFiles, sharedParamFiles, contextFiles]);
}
