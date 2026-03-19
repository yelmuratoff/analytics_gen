import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';
import type { StudioState, ConfigState, EventDef, ParamDef } from '../types/index.ts';
import { DEFAULT_EVENT_DESCRIPTION } from '../schemas/constants.ts';

/** Placeholder config — replaced by schema-derived defaults on first load.
 *  See App.tsx: applySchemaDefaults() fills real values from schema.
 *  This is only used before schemas are loaded (splash screen). */
let schemaDefaultConfig: ConfigState | null = null;

/** Called from App.tsx after schemas load to set the real defaults */
export function setSchemaDefaultConfig(config: ConfigState) {
  schemaDefaultConfig = config;
  // If store still has empty config (first visit), apply defaults
  const current = useStore.getState().config;
  if (!current.outputs.dart) {
    useStore.getState().setConfig(config);
  }
}

function getDefaultConfig(): ConfigState {
  if (schemaDefaultConfig) return schemaDefaultConfig;
  // Minimal placeholder — will be overridden by schema defaults
  return { inputs: { events: '', shared_parameters: [], contexts: [], imports: [] }, outputs: { dart: '' }, targets: {}, rules: {}, naming: { casing: '', enforce_snake_case_domains: false, enforce_snake_case_parameters: false, event_name_template: '', identifier_template: '', domain_aliases: {} }, meta: {} } as unknown as ConfigState;
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

export const useStore = create<StudioState>()(
  persist(
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
      name: 'analytics-gen-studio',
      version: 1,
    },
  ),
);
