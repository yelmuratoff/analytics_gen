import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';
import { temporal } from 'zundo';
import type { StudioState, ConfigState, EventDef, ParamDef } from '../types/index.ts';
import { DEFAULT_EVENT_DESCRIPTION } from '../schemas/constants.ts';

/** Placeholder config — replaced by schema-derived defaults on first load.
 *  See App.tsx: applySchemaDefaults() fills real values from schema.
 *  This is only used before schemas are loaded (splash screen). */
let schemaDefaultConfig: ConfigState | null = null;

/** Called from App.tsx after schemas load to set the real defaults */
export function setSchemaDefaultConfig(config: ConfigState) {
  schemaDefaultConfig = config;
  // If store still has empty/placeholder config (first visit), apply schema defaults
  const current = useStore.getState().config;
  const cfg = current as unknown as Record<string, unknown>;
  const hasData = Object.values(cfg).some((v) =>
    typeof v === 'object' && v !== null && Object.values(v as Record<string, unknown>).some((fv) =>
      fv !== '' && fv !== false && !(Array.isArray(fv) && fv.length === 0) && !(typeof fv === 'object' && fv !== null && Object.keys(fv).length === 0)
    )
  );
  if (!hasData) {
    useStore.getState().setConfig(config);
  }
}

function getDefaultConfig(): ConfigState {
  if (schemaDefaultConfig) return schemaDefaultConfig;
  // Empty placeholder — will be overridden by schema defaults after load
  return {} as ConfigState;
}

const initialState = {
  activeTab: 'config' as const,
  config: getDefaultConfig(),
  eventFiles: [],
  sharedParamFiles: [],
  contextFiles: [],
  selectedPath: null,
  errors: [],
};

function uniqueName(base: string, existing: string[]): string {
  let name = `${base}_copy`;
  let i = 2;
  while (existing.includes(name)) {
    name = `${base}_copy_${i}`;
    i++;
  }
  return name;
}

export const useStore = create<StudioState>()(
  persist(
    temporal(
      immer((set) => ({
        ...initialState,

        setActiveTab: (tab) => set((s) => { s.activeTab = tab; }),
        setConfig: (config) => set((s) => { s.config = config; }),
        updateConfig: (updater) => set((s) => { updater(s.config); }),

        // Event file actions
        addEventFile: (fileName) => set((s) => {
          s.eventFiles.push({ fileName, domains: {} });
        }),
        removeEventFile: (index) => set((s) => {
          s.eventFiles.splice(index, 1);
          s.selectedPath = null;
        }),
        addDomain: (fileIndex, domainName) => set((s) => {
          s.eventFiles[fileIndex].domains[domainName] = {};
        }),
        removeDomain: (fileIndex, domainName) => set((s) => {
          delete s.eventFiles[fileIndex].domains[domainName];
          s.selectedPath = null;
        }),
        addEvent: (fileIndex, domain, eventName) => set((s) => {
          s.eventFiles[fileIndex].domains[domain][eventName] = {
            description: DEFAULT_EVENT_DESCRIPTION,
            parameters: {},
          } as EventDef;
        }),
        removeEvent: (fileIndex, domain, eventName) => set((s) => {
          delete s.eventFiles[fileIndex].domains[domain][eventName];
          s.selectedPath = null;
        }),
        updateEvent: (fileIndex, domain, eventName, event) => set((s) => {
          const existing = s.eventFiles[fileIndex].domains[domain][eventName];
          s.eventFiles[fileIndex].domains[domain][eventName] = { ...event, parameters: existing.parameters };
        }),
        addParameter: (fileIndex, domain, eventName, paramName, value) => set((s) => {
          s.eventFiles[fileIndex].domains[domain][eventName].parameters[paramName] = value as ParamDef | string | null;
        }),
        removeParameter: (fileIndex, domain, eventName, paramName) => set((s) => {
          delete s.eventFiles[fileIndex].domains[domain][eventName].parameters[paramName];
        }),
        updateParameter: (fileIndex, domain, eventName, paramName, value) => set((s) => {
          s.eventFiles[fileIndex].domains[domain][eventName].parameters[paramName] = value as ParamDef | string | null;
        }),

        // Shared param actions
        addSharedParamFile: (fileName) => set((s) => {
          s.sharedParamFiles.push({ fileName, parameters: {} });
        }),
        removeSharedParamFile: (index) => set((s) => {
          s.sharedParamFiles.splice(index, 1);
          s.selectedPath = null;
        }),
        addSharedParam: (fileIndex, paramName, value) => set((s) => {
          s.sharedParamFiles[fileIndex].parameters[paramName] = value;
        }),
        removeSharedParam: (fileIndex, paramName) => set((s) => {
          delete s.sharedParamFiles[fileIndex].parameters[paramName];
        }),
        updateSharedParam: (fileIndex, paramName, value) => set((s) => {
          s.sharedParamFiles[fileIndex].parameters[paramName] = value;
        }),

        // Context actions
        addContextFile: (fileName, contextName) => set((s) => {
          s.contextFiles.push({ fileName, contextName, properties: {} });
        }),
        removeContextFile: (index) => set((s) => {
          s.contextFiles.splice(index, 1);
          s.selectedPath = null;
        }),
        addContextProperty: (fileIndex, propName, value) => set((s) => {
          s.contextFiles[fileIndex].properties[propName] = value;
        }),
        removeContextProperty: (fileIndex, propName) => set((s) => {
          delete s.contextFiles[fileIndex].properties[propName];
        }),
        updateContextProperty: (fileIndex, propName, value) => set((s) => {
          s.contextFiles[fileIndex].properties[propName] = value;
        }),

        // Duplicate actions
        duplicateEvent: (fileIndex, domain, eventName) => set((s) => {
          const events = s.eventFiles[fileIndex].domains[domain];
          const source = events[eventName];
          if (!source) return;
          const newName = uniqueName(eventName, Object.keys(events));
          events[newName] = JSON.parse(JSON.stringify(source));
          s.selectedPath = { tab: 'events', fileIndex, domain, event: newName };
        }),
        duplicateParameter: (fileIndex, domain, eventName, paramName) => set((s) => {
          const params = s.eventFiles[fileIndex].domains[domain][eventName].parameters;
          const source = params[paramName];
          if (source === undefined) return;
          const newName = uniqueName(paramName, Object.keys(params));
          params[newName] = source === null ? null : JSON.parse(JSON.stringify(source));
          s.selectedPath = { tab: 'events', fileIndex, domain, event: eventName, parameter: newName };
        }),

        // Import actions
        importEventFile: (file) => set((s) => {
          const exists = s.eventFiles.findIndex((f) => f.fileName === file.fileName);
          if (exists >= 0) {
            // Merge domains into existing file
            for (const [dn, events] of Object.entries(file.domains)) {
              if (!s.eventFiles[exists].domains[dn]) s.eventFiles[exists].domains[dn] = {};
              Object.assign(s.eventFiles[exists].domains[dn], events);
            }
          } else {
            s.eventFiles.push(file);
          }
        }),
        importSharedParamFile: (file) => set((s) => {
          const exists = s.sharedParamFiles.findIndex((f) => f.fileName === file.fileName);
          if (exists >= 0) {
            Object.assign(s.sharedParamFiles[exists].parameters, file.parameters);
          } else {
            s.sharedParamFiles.push(file);
          }
        }),
        importContextFile: (file) => set((s) => {
          const exists = s.contextFiles.findIndex((f) => f.fileName === file.fileName);
          if (exists >= 0) {
            Object.assign(s.contextFiles[exists].properties, file.properties);
          } else {
            s.contextFiles.push(file);
          }
        }),
        mergeConfig: (partial) => set((s) => {
          for (const [section, values] of Object.entries(partial)) {
            if (typeof values === 'object' && values !== null) {
              const cfg = s.config as unknown as Record<string, Record<string, unknown>>;
              if (!cfg[section]) cfg[section] = {};
              Object.assign(cfg[section], values);
            }
          }
        }),

        // Rename actions
        renameEventFile: (fileIndex, newName) => set((s) => {
          s.eventFiles[fileIndex].fileName = newName;
        }),
        renameDomain: (fileIndex, oldName, newName) => set((s) => {
          const domains = s.eventFiles[fileIndex].domains;
          if (oldName === newName || !domains[oldName]) return;
          // Preserve key order: rebuild object
          const entries = Object.entries(domains);
          const rebuilt: typeof domains = {};
          for (const [k, v] of entries) {
            rebuilt[k === oldName ? newName : k] = v;
          }
          s.eventFiles[fileIndex].domains = rebuilt;
          if (s.selectedPath?.domain === oldName) s.selectedPath.domain = newName;
        }),
        renameEvent: (fileIndex, domain, oldName, newName) => set((s) => {
          const events = s.eventFiles[fileIndex].domains[domain];
          if (oldName === newName || !events[oldName]) return;
          const entries = Object.entries(events);
          const rebuilt: typeof events = {};
          for (const [k, v] of entries) {
            rebuilt[k === oldName ? newName : k] = v;
          }
          s.eventFiles[fileIndex].domains[domain] = rebuilt;
          if (s.selectedPath?.event === oldName) s.selectedPath.event = newName;
        }),
        renameParameter: (fileIndex, domain, eventName, oldName, newName) => set((s) => {
          const params = s.eventFiles[fileIndex].domains[domain][eventName].parameters;
          if (oldName === newName || !(oldName in params)) return;
          const entries = Object.entries(params);
          const rebuilt: typeof params = {};
          for (const [k, v] of entries) {
            rebuilt[k === oldName ? newName : k] = v;
          }
          s.eventFiles[fileIndex].domains[domain][eventName].parameters = rebuilt;
          if (s.selectedPath?.parameter === oldName) s.selectedPath.parameter = newName;
        }),

        setSelectedPath: (path) => set((s) => { s.selectedPath = path; }),

        resetState: () => set(() => ({ ...initialState, config: getDefaultConfig() })),
        loadProject: (data) => set(() => ({
          ...initialState,
          ...(data.activeTab && { activeTab: data.activeTab }),
          ...(data.config && { config: data.config }),
          ...(data.eventFiles && { eventFiles: data.eventFiles }),
          ...(data.sharedParamFiles && { sharedParamFiles: data.sharedParamFiles }),
          ...(data.contextFiles && { contextFiles: data.contextFiles }),
        })),
      })),
      {
        limit: 50,
        partialize: (state) => {
          const { activeTab: _, selectedPath: _s, errors: _e, ...data } = state;
          return data;
        },
      },
    ),
    {
      name: 'analytics-gen-studio',
      version: 1,
    },
  ),
);
