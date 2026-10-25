import type { FormValidation } from '@rjsf/utils';
import {
  SNAKE_CASE_PARAM,
  SNAKE_CASE_DOMAIN,
  PARAM_MUTUAL_EXCLUSIONS,
  TYPE_RESTRICTED_FIELDS,
} from '../schemas/constants.ts';
import type { ValidationError, ParamDef, ConfigState, EventFile, SharedParamFile, ContextFile, TabId } from '../types/index.ts';

/** A rule that one field of a parameter definition breaks. */
export interface ParamViolation {
  field: string;
  message: string;
}

/** Returns the error shown for a parameter or property name that breaks the snake_case rule. */
export function snakeCaseNameError(name: string, enforceSnakeCase: boolean): string | null {
  if (!enforceSnakeCase || SNAKE_CASE_PARAM.test(name)) return null;
  return `"${name}" must be snake_case (a-z, 0-9, _)`;
}

/** Whether a custom event name uses `{ }` placeholders while strict_event_names forbids them. */
export function breaksStrictEventNames(eventName: string | undefined, strictEventNames: boolean): boolean {
  return strictEventNames && !!eventName && (eventName.includes('{') || eventName.includes('}'));
}

function isSet(value: unknown): boolean {
  return value !== undefined && value !== '' && !(Array.isArray(value) && value.length === 0);
}

/** Lists the rules a parameter definition breaks, each tied to the field that breaks it. */
export function paramViolations(param: ParamDef): ParamViolation[] {
  const violations: ParamViolation[] = [];
  const fields = param as Record<string, unknown>;

  for (const [fieldA, fieldB] of PARAM_MUTUAL_EXCLUSIONS) {
    if (isSet(fields[fieldA]) && isSet(fields[fieldB])) {
      violations.push({ field: fieldB, message: `${fieldA} and ${fieldB} cannot be used together` });
    }
  }

  if (param.regex?.includes("'''")) {
    violations.push({ field: 'regex', message: "regex cannot contain triple quotes (''')" });
  }

  const baseType = param.type?.replace(/\?$/, '').toLowerCase();
  if (baseType) {
    for (const [field, supportedTypes] of Object.entries(TYPE_RESTRICTED_FIELDS)) {
      if (isSet(fields[field]) && !supportedTypes.includes(baseType)) {
        violations.push({ field, message: `${field} only applies to ${supportedTypes.join(', ')} parameters` });
      }
    }
  }

  if (param.min_length !== undefined && param.max_length !== undefined && param.max_length < param.min_length) {
    violations.push({ field: 'max_length', message: 'max_length must be >= min_length' });
  }
  if (param.min !== undefined && param.max !== undefined && param.max < param.min) {
    violations.push({ field: 'max', message: 'max must be >= min' });
  }
  if (param.identifier && !SNAKE_CASE_PARAM.test(param.identifier)) {
    violations.push({ field: 'identifier', message: `identifier "${param.identifier}" must be snake_case` });
  }

  return violations;
}

type FieldErrors = Record<string, { addError: (message: string) => void } | undefined>;

/** RJSF `customValidate` for a parameter definition: attaches each violation to its field. */
export function validateParamForm<T>(data: T | undefined, errors: FormValidation<T>): FormValidation<T> {
  if (!data) return errors;
  const fieldErrors = errors as unknown as FieldErrors;
  for (const { field, message } of paramViolations(data as ParamDef)) {
    fieldErrors[field]?.addError(message);
  }
  return errors;
}

function validateParam(
  paramName: string,
  param: ParamDef | string | null,
  path: string,
  tab: Exclude<TabId, 'config'>,
  enforceSnakeParams: boolean,
): ValidationError[] {
  const errors: ValidationError[] = [];
  const nameError = snakeCaseNameError(paramName, enforceSnakeParams);
  if (nameError) errors.push({ path, message: nameError, tab });
  if (param === null || typeof param === 'string') return errors;
  for (const { message } of paramViolations(param)) {
    errors.push({ path, message, tab });
  }
  return errors;
}

/** Validates the whole project for the error panel and the export gate. */
export function computeValidation(config: ConfigState, eventFiles: EventFile[], sharedParamFiles: SharedParamFile[], contextFiles: ContextFile[]): ValidationError[] {
  const errors: ValidationError[] = [];
  const enforceSnakeDomains = !!config.naming?.enforce_snake_case_domains;
  const enforceSnakeParams = !!config.naming?.enforce_snake_case_parameters;
  const strictEventNames = !!config.rules?.strict_event_names;

  if (!config.outputs?.dart) {
    errors.push({ path: 'config.outputs.dart', message: 'Dart output path is required', tab: 'config' });
  }

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

    const domains = file.domains ?? {};
    if (Object.keys(domains).length === 0) {
      errors.push({ path: `events.${file.fileName}`, message: 'File has no domains', tab: 'events', fileIndex: fi });
    }

    for (const [domainName, events] of Object.entries(domains)) {
      if (enforceSnakeDomains && !SNAKE_CASE_DOMAIN.test(domainName)) {
        errors.push({ path: `events.${file.fileName}.${domainName}`, message: `Domain "${domainName}" must be snake_case`, tab: 'events', fileIndex: fi, domain: domainName });
      }

      for (const [eventName, event] of Object.entries(events ?? {})) {
        const ePath = `events.${file.fileName}.${domainName}.${eventName}`;
        const nav = { fileIndex: fi, domain: domainName, event: eventName };

        if (breaksStrictEventNames(event.event_name as string | undefined, strictEventNames)) {
          errors.push({ path: ePath, message: 'event_name cannot contain { } when strict_event_names is enabled', tab: 'events', ...nav });
        }

        for (const [paramName, paramVal] of Object.entries(event.parameters ?? {})) {
          errors.push(...validateParam(paramName, paramVal, `${ePath}.${paramName}`, 'events', enforceSnakeParams).map((e) => ({ ...e, ...nav, parameter: paramName })));
        }
      }
    }
  }

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

    for (const [paramName, paramVal] of Object.entries(file.parameters ?? {})) {
      errors.push(...validateParam(paramName, paramVal, `shared.${file.fileName}.${paramName}`, 'shared', enforceSnakeParams).map((e) => ({ ...e, fileIndex: fi, parameter: paramName })));
    }
  }

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

    for (const [propName, propVal] of Object.entries(file.properties ?? {})) {
      errors.push(...validateParam(propName, propVal, `contexts.${file.fileName}.${propName}`, 'contexts', enforceSnakeParams).map((e) => ({ ...e, fileIndex: fi, contextProperty: propName })));
    }
  }

  return errors;
}
