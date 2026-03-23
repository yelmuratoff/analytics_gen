import { useCallback } from 'react';
import type { FormValidation } from '@rjsf/utils';
import {
  NON_NUMERIC_TYPES, PARAM_MUTUAL_EXCLUSIONS,
  STRING_ONLY_FIELDS, NUMERIC_ONLY_FIELDS,
} from '../schemas/constants.ts';
import type { ParamDef } from '../types/index.ts';

/**
 * Shared parameter validation logic used by ParameterEditor,
 * SharedParamEditor, and ContextPropertyEditor.
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function useParameterValidation(): (data: any, errors: FormValidation) => FormValidation {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return useCallback((data: any, errors: FormValidation) => {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const e = errors as any;
    const baseType = data.type?.replace(/\?$/, '');
    const isStringLike = baseType === 'string';
    const isNumericLike = baseType ? !NON_NUMERIC_TYPES.has(baseType) : false;

    // Mutual exclusion checks
    for (const [a, b] of PARAM_MUTUAL_EXCLUSIONS) {
      const valA = data[a as keyof ParamDef];
      const valB = data[b as keyof ParamDef];
      const hasA = valA !== undefined && valA !== '' && !(Array.isArray(valA) && valA.length === 0);
      const hasB = valB !== undefined && valB !== '' && !(Array.isArray(valB) && valB.length === 0);
      if (hasA && hasB) {
        e[b]?.addError(`${a} and ${b} cannot be used together`);
      }
    }

    // Regex triple quotes
    if (data.regex && data.regex.includes("'''")) {
      e.regex?.addError("regex cannot contain triple quotes (''')");
    }

    // String-only fields
    for (const field of STRING_ONLY_FIELDS) {
      if (data[field as keyof ParamDef] !== undefined && baseType && !isStringLike) {
        e[field]?.addError(`${field} only applies to string type`);
      }
    }

    // Numeric-only fields
    for (const field of NUMERIC_ONLY_FIELDS) {
      if (data[field as keyof ParamDef] !== undefined && baseType && !isNumericLike) {
        e[field]?.addError(`${field} only applies to numeric types`);
      }
    }

    // Range checks
    if (data.min_length !== undefined && data.max_length !== undefined && data.max_length < data.min_length) {
      e.max_length?.addError('max_length must be >= min_length');
    }
    if (data.min !== undefined && data.max !== undefined && data.max < data.min) {
      e.max?.addError('max must be >= min');
    }

    return errors;
  }, []);
}

/** Count how many advanced fields (non-type, non-empty) are set. */
export function countAdvancedFields(formData: ParamDef, excludeFields: string[] = []): number {
  const exclude = new Set(['type', ...excludeFields]);
  return Object.entries(formData).filter(([k, v]) => {
    if (exclude.has(k)) return false;
    if (v == null || v === '') return false;
    if (Array.isArray(v) && v.length === 0) return false;
    return true;
  }).length;
}
