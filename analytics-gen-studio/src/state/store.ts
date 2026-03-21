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
