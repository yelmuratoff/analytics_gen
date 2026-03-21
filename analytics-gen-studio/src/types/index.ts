// Re-export schema-generated types as app-friendly aliases.
// Source of truth: generated.ts (auto-generated from JSON schemas).
// Run `npm run generate-types` after changing schemas.

// ParamDef re-exported as ParamDef (relaxed operations type) below
export type {
  InputConfiguration,
  OutputConfiguration,
  GenerationTargets,
  ValidationGenerationRules,
  NamingStrategy,
  MetaConfiguration,
} from './generated.ts';

import type {
  AnalyticsGenRoot,
  InputConfiguration,
  OutputConfiguration,
  GenerationTargets,
  ValidationGenerationRules,
  NamingStrategy,
  MetaConfiguration,
} from './generated.ts';

/** App-level ConfigState — all sections required (schema makes them optional, app guarantees they exist) */
export type ConfigState = Required<Pick<AnalyticsGenRoot,
  'inputs' | 'outputs' | 'targets' | 'rules' | 'naming' | 'meta'
>> & {
  inputs: Required<InputConfiguration>;
  outputs: Required<Pick<OutputConfiguration, 'dart'>> & Omit<OutputConfiguration, 'dart'>;
  targets: Required<GenerationTargets>;
  rules: Required<ValidationGenerationRules>;
  naming: Required<NamingStrategy>;
  meta: Required<MetaConfiguration>;
};

// EventDef is not in the schema directly (schema uses $defs.event with $ref to parameter).
// We define it here using the generated ParamDef.
import type { AnalyticsParameter } from './generated.ts';

/** ParamDef — from generated schema, with relaxed operations and no index signature */
type CleanParam = {
  [K in keyof AnalyticsParameter as string extends K ? never : K]: AnalyticsParameter[K];
};
export type ParamDef = Omit<CleanParam, 'operations'> & { operations?: string[] };

export interface EventDef {
  [key: string]: unknown; // allow any event field from schema
  parameters: Record<string, ParamDef | string | null>;
}

// App-level file wrappers (not in any schema — these are Studio's internal structure)
export interface EventFile {
  fileName: string;
  domains: Record<string, Record<string, EventDef>>;
}

export interface SharedParamFile {
  fileName: string;
  parameters: Record<string, ParamDef | string>;
}

export interface ContextFile {
  fileName: string;
  contextName: string;
  properties: Record<string, ParamDef | string>;
}

// UI state types (app-only, never in schemas)
export type TabId = 'config' | 'events' | 'shared' | 'contexts';

export interface SelectionPath {
  tab: TabId;
  fileIndex: number;
  domain?: string;
  event?: string;
  parameter?: string;
  contextProperty?: string;
}

export interface ValidationError {
  path: string;
  message: string;
  tab: TabId;
  /** Navigation fields for click-to-navigate from error panel */
  fileIndex?: number;
  domain?: string;
  event?: string;
  parameter?: string;
  contextProperty?: string;
}

export interface StudioState {
  activeTab: TabId;
  config: ConfigState;
  eventFiles: EventFile[];
  sharedParamFiles: SharedParamFile[];
  contextFiles: ContextFile[];
  selectedPath: SelectionPath | null;
  errors: ValidationError[];

  // Actions
  setActiveTab: (tab: TabId) => void;
  setConfig: (config: ConfigState) => void;
  updateConfig: (updater: (config: ConfigState) => void) => void;

  addEventFile: (fileName: string) => void;
  removeEventFile: (index: number) => void;
  addDomain: (fileIndex: number, domainName: string) => void;
  removeDomain: (fileIndex: number, domainName: string) => void;
  addEvent: (fileIndex: number, domain: string, eventName: string) => void;
  removeEvent: (fileIndex: number, domain: string, eventName: string) => void;
  updateEvent: (fileIndex: number, domain: string, eventName: string, event: EventDef) => void;
  addParameter: (fileIndex: number, domain: string, eventName: string, paramName: string, value: ParamDef | string | null) => void;
  removeParameter: (fileIndex: number, domain: string, eventName: string, paramName: string) => void;
  updateParameter: (fileIndex: number, domain: string, eventName: string, paramName: string, value: ParamDef | string | null) => void;

  addSharedParamFile: (fileName: string) => void;
  removeSharedParamFile: (index: number) => void;
  addSharedParam: (fileIndex: number, paramName: string, value: ParamDef | string) => void;
  removeSharedParam: (fileIndex: number, paramName: string) => void;
  updateSharedParam: (fileIndex: number, paramName: string, value: ParamDef | string) => void;

  addContextFile: (fileName: string, contextName: string) => void;
  removeContextFile: (index: number) => void;
  addContextProperty: (fileIndex: number, propName: string, value: ParamDef | string) => void;
  removeContextProperty: (fileIndex: number, propName: string) => void;
  updateContextProperty: (fileIndex: number, propName: string, value: ParamDef | string) => void;

  duplicateEvent: (fileIndex: number, domain: string, eventName: string) => void;
  duplicateParameter: (fileIndex: number, domain: string, eventName: string, paramName: string) => void;

  renameEventFile: (fileIndex: number, newName: string) => void;
  renameDomain: (fileIndex: number, oldName: string, newName: string) => void;
  renameEvent: (fileIndex: number, domain: string, oldName: string, newName: string) => void;
  renameParameter: (fileIndex: number, domain: string, eventName: string, oldName: string, newName: string) => void;

  importEventFile: (file: import('./index.ts').EventFile) => void;
  importSharedParamFile: (file: import('./index.ts').SharedParamFile) => void;
  importContextFile: (file: import('./index.ts').ContextFile) => void;
  mergeConfig: (partial: Partial<ConfigState>) => void;

  setSelectedPath: (path: SelectionPath | null) => void;
  resetState: () => void;
  loadProject: (state: Partial<StudioState>) => void;
}
