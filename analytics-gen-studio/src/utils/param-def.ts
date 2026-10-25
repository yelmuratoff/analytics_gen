import { DEFAULT_PARAM_TYPE } from '../schemas/constants.ts';
import type { ParamDef } from '../types/index.ts';

/** Expands the compact `name: type` form and empty entries into a full parameter definition. */
export function toParamDef(raw: ParamDef | string | null | undefined): ParamDef {
  if (typeof raw === 'string') return { type: raw };
  return raw ?? { type: DEFAULT_PARAM_TYPE };
}
