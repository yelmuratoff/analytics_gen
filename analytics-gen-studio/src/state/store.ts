import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';
import { shallow } from 'zustand/shallow';
import { temporal } from 'zundo';
import type { StudioState, ConfigState, EventDef, ParamDef } from '../types/index.ts';
import { DEFAULT_EVENT_DESCRIPTION } from '../schemas/constants.ts';
import { newProjectId } from '../utils/project-meta.ts';
import { withDefaults } from '../utils/config-defaults.ts';

/** Placeholder config — replaced by schema-derived defaults on first load.
 *  See App.tsx: applySchemaDefaults() fills real values from schema.
 *  This is only used before schemas are loaded (splash screen). */
let schemaDefaultConfig: ConfigState | null = null;

/** Called from App.tsx after schemas load: records the defaults and fills in any setting the current config lacks. */
export function setSchemaDefaultConfig(config: ConfigState) {
  schemaDefaultConfig = config;
  const history = useStore.temporal.getState();
  history.pause();
  useStore.setState((s) => ({ config: withDefaults(s.config, config) }));
  history.resume();
}

function getDefaultConfig(): ConfigState {
  if (schemaDefaultConfig) return schemaDefaultConfig;
  // Empty placeholder — will be overridden by schema defaults after load
  return {} as ConfigState;
}

const initialState = {
  activeTab: 'config' as const,
  projectId: newProjectId(),
  projectName: '',
  config: getDefaultConfig(),
  eventFiles: [],
  sharedParamFiles: [],
  contextFiles: [],
  selectedPath: null,
  errors: [],
};

/** Returns a copy of `record` with `oldName` renamed in place, or null when there is nothing to rename or `newName` is taken. */
function renameKey<T>(record: Record<string, T>, oldName: string, newName: string): Record<string, T> | null {
  if (oldName === newName || !(oldName in record) || newName in record) return null;
  return Object.fromEntries(Object.entries(record).map(([k, v]) => [k === oldName ? newName : k, v]));
}

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
        setProjectName: (name) => set((s) => { s.projectName = name; }),
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
          const renamed = renameKey(s.eventFiles[fileIndex].domains, oldName, newName);
          if (!renamed) return;
          s.eventFiles[fileIndex].domains = renamed;
          if (s.selectedPath?.domain === oldName) s.selectedPath.domain = newName;
        }),
        renameEvent: (fileIndex, domain, oldName, newName) => set((s) => {
          const renamed = renameKey(s.eventFiles[fileIndex].domains[domain], oldName, newName);
          if (!renamed) return;
          s.eventFiles[fileIndex].domains[domain] = renamed;
          if (s.selectedPath?.event === oldName) s.selectedPath.event = newName;
        }),
        renameParameter: (fileIndex, domain, eventName, oldName, newName) => set((s) => {
          const event = s.eventFiles[fileIndex].domains[domain][eventName];
          const renamed = renameKey(event.parameters, oldName, newName);
          if (!renamed) return;
          event.parameters = renamed;
          if (s.selectedPath?.parameter === oldName) s.selectedPath.parameter = newName;
        }),
        renameSharedParamFile: (fileIndex, newName) => set((s) => {
          s.sharedParamFiles[fileIndex].fileName = newName;
        }),
        renameSharedParam: (fileIndex, oldName, newName) => set((s) => {
          const file = s.sharedParamFiles[fileIndex];
          const renamed = renameKey(file.parameters, oldName, newName);
          if (!renamed) return;
          file.parameters = renamed;
          if (!s.sharedParamFiles.some((f) => oldName in f.parameters)) {
            for (const eventFile of s.eventFiles) {
              for (const events of Object.values(eventFile.domains)) {
                for (const event of Object.values(events)) {
                  if (event.parameters[oldName] !== null) continue;
                  const references = renameKey(event.parameters, oldName, newName);
                  if (references) event.parameters = references;
                }
              }
            }
          }
          if (s.selectedPath?.parameter === oldName) s.selectedPath.parameter = newName;
        }),
        renameContextFile: (fileIndex, newName) => set((s) => {
          s.contextFiles[fileIndex].fileName = newName;
        }),
        renameContextName: (fileIndex, newName) => set((s) => {
          s.contextFiles[fileIndex].contextName = newName;
        }),
        renameContextProperty: (fileIndex, oldName, newName) => set((s) => {
          const file = s.contextFiles[fileIndex];
          const renamed = renameKey(file.properties, oldName, newName);
          if (!renamed) return;
          file.properties = renamed;
          if (s.selectedPath?.contextProperty === oldName) s.selectedPath.contextProperty = newName;
        }),

        setSelectedPath: (path) => set((s) => { s.selectedPath = path; }),

        resetState: () => set(() => ({
          ...initialState,
          projectId: newProjectId(),
          projectName: '',
          config: getDefaultConfig(),
        })),
        loadProject: (data) => set(() => ({
          ...initialState,
          projectId: data.projectId ?? newProjectId(),
          projectName: data.projectName ?? '',
          ...(data.activeTab && { activeTab: data.activeTab }),
          ...(data.config && { config: withDefaults(data.config, getDefaultConfig()) }),
          ...(data.eventFiles && { eventFiles: data.eventFiles }),
          ...(data.sharedParamFiles && { sharedParamFiles: data.sharedParamFiles }),
          ...(data.contextFiles && { contextFiles: data.contextFiles }),
        })),
      })),
      {
        limit: 50,
        partialize: ({ projectId, projectName, config, eventFiles, sharedParamFiles, contextFiles }) =>
          ({ projectId, projectName, config, eventFiles, sharedParamFiles, contextFiles }),
        equality: shallow,
      },
    ),
    {
      name: 'analytics-gen-studio',
      version: 1,
    },
  ),
);
