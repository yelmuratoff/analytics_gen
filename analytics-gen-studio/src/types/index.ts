export interface ParamDef {
  type?: string;
  description?: string;
  identifier?: string;
  param_name?: string;
  dart_type?: string;
  import?: string;
  allowed_values?: unknown[];
  regex?: string;
  min_length?: number;
  max_length?: number;
  min?: number;
  max?: number;
  meta?: Record<string, unknown>;
  operations?: string[];
  added_in?: string;
  deprecated_in?: string;
}

export interface EventDef {
  description?: string;
  event_name?: string;
  identifier?: string;
  deprecated?: boolean;
  replacement?: string;
  added_in?: string;
  deprecated_in?: string;
  dual_write_to?: string[];
  meta?: Record<string, unknown>;
  parameters: Record<string, ParamDef | string | null>;
}

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

export interface ConfigState {
  inputs: {
    events: string;
    shared_parameters: string[];
    contexts: string[];
    imports: string[];
  };
  outputs: {
    dart: string;
    docs?: string;
    exports?: string;
  };
  targets: {
    csv: boolean;
    json: boolean;
    sql: boolean;
    docs: boolean;
    plan: boolean;
    test_matchers: boolean;
  };
  rules: {
    include_event_description: boolean;
    strict_event_names: boolean;
    enforce_centrally_defined_parameters: boolean;
    prevent_event_parameter_duplicates: boolean;
  };
  naming: {
    casing: string;
    enforce_snake_case_domains: boolean;
    enforce_snake_case_parameters: boolean;
    event_name_template: string;
    identifier_template: string;
    domain_aliases: Record<string, string>;
  };
  meta: {
    auto_tracking_creation_date: boolean;
    include_meta_in_parameters: boolean;
  };
}

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

  // Event actions
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

  // Shared param actions
  addSharedParamFile: (fileName: string) => void;
  removeSharedParamFile: (index: number) => void;
  addSharedParam: (fileIndex: number, paramName: string, value: ParamDef | string) => void;
  removeSharedParam: (fileIndex: number, paramName: string) => void;
  updateSharedParam: (fileIndex: number, paramName: string, value: ParamDef | string) => void;

  // Context actions
  addContextFile: (fileName: string, contextName: string) => void;
  removeContextFile: (index: number) => void;
  addContextProperty: (fileIndex: number, propName: string, value: ParamDef | string) => void;
  removeContextProperty: (fileIndex: number, propName: string) => void;
  updateContextProperty: (fileIndex: number, propName: string, value: ParamDef | string) => void;

  // Selection
  setSelectedPath: (path: SelectionPath | null) => void;

  // Project
  resetState: () => void;
  loadProject: (state: Partial<StudioState>) => void;
}
