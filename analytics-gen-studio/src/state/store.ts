import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';
import type { StudioState, ConfigState, EventDef, ParamDef } from '../types/index.ts';
import { DEFAULT_EVENT_DESCRIPTION } from '../schemas/constants.ts';

/** Initial defaults matching the JSON schema defaults.
 *  These are overridden by schema-derived defaults when schemas load (see App.tsx).
 *  If schemas add new defaults, they take precedence at runtime. */
const fallbackConfig: ConfigState = {
  inputs: { events: 'events', shared_parameters: [], contexts: [], imports: [] },
  outputs: { dart: 'lib/src/analytics/generated' },
  targets: { csv: false, json: false, sql: false, docs: false, plan: true, test_matchers: false },
  rules: { include_event_description: false, strict_event_names: true, enforce_centrally_defined_parameters: false, prevent_event_parameter_duplicates: false },
  naming: { casing: 'snake_case', enforce_snake_case_domains: true, enforce_snake_case_parameters: true, event_name_template: '{domain}: {event}', identifier_template: '{domain}: {event}', domain_aliases: {} },
  meta: { auto_tracking_creation_date: false, include_meta_in_parameters: false },
};

const initialState = {
  activeTab: 'config' as const,
  config: fallbackConfig,
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

      resetState: () => set(() => ({ ...initialState })),
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
