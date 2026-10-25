import { useSyncExternalStore } from 'react';
import { useStore } from '../state/store.ts';
import { computeValidation } from '../utils/validation.ts';
import type { ValidationError } from '../types/index.ts';

function errorsEqual(a: ValidationError[], b: ValidationError[]): boolean {
  if (a.length !== b.length) return false;
  for (let i = 0; i < a.length; i++) {
    if (a[i].path !== b[i].path || a[i].message !== b[i].message || a[i].tab !== b[i].tab) return false;
  }
  return true;
}

// ── Singleton validation store ──
// Validation is computed once and shared across all consumers (TabBar, Toolbar, YamlPreview).
// Debounced at 200ms — recomputes only when store data actually changes.

let cachedErrors: ValidationError[] = [];
let cachedErrorKeys: Set<string> = new Set();
let cachedErrorMessages: Map<string, string[]> = new Map();
const listeners = new Set<() => void>();

// Builds hierarchical keys so parents show errors from children.
// Keys: "events:0", "events:0:auth", "events:0:auth:login", "events:0:auth:login:user_id"
function buildErrorKeysAndMessages(errors: ValidationError[]): { keys: Set<string>; messages: Map<string, string[]> } {
  const keys = new Set<string>();
  const messages = new Map<string, string[]>();
  const addKey = (key: string, msg: string) => {
    keys.add(key);
    const existing = messages.get(key);
    if (existing) existing.push(msg);
    else messages.set(key, [msg]);
  };
  for (const err of errors) {
    if (err.fileIndex === undefined) continue;
    const tab = err.tab;
    addKey(`${tab}:${err.fileIndex}`, err.message);
    if (tab === 'events') {
      if (err.domain) {
        addKey(`${tab}:${err.fileIndex}:${err.domain}`, err.message);
        if (err.event) {
          addKey(`${tab}:${err.fileIndex}:${err.domain}:${err.event}`, err.message);
          if (err.parameter) {
            addKey(`${tab}:${err.fileIndex}:${err.domain}:${err.event}:${err.parameter}`, err.message);
          }
        }
      }
    } else if (tab === 'shared') {
      if (err.parameter) addKey(`${tab}:${err.fileIndex}:${err.parameter}`, err.message);
    } else if (tab === 'contexts') {
      if (err.contextProperty) addKey(`${tab}:${err.fileIndex}:${err.contextProperty}`, err.message);
    }
  }
  return { keys, messages };
}

function emitChange() {
  const result = buildErrorKeysAndMessages(cachedErrors);
  cachedErrorKeys = result.keys;
  cachedErrorMessages = result.messages;
  for (const listener of listeners) listener();
}

let debounceTimer: ReturnType<typeof setTimeout> | undefined;

function recompute() {
  const { config, eventFiles, sharedParamFiles, contextFiles } = useStore.getState();
  const next = computeValidation(config, eventFiles, sharedParamFiles, contextFiles);
  if (errorsEqual(next, cachedErrors)) return;
  cachedErrors = next;
  emitChange();
}

// Subscribe to the main store once (module-level side effect)
useStore.subscribe(() => {
  clearTimeout(debounceTimer);
  debounceTimer = setTimeout(recompute, 200);
});

recompute();

/** Recomputes validation right away, for when schema-derived rules change without a store update. */
export function refreshValidation() {
  clearTimeout(debounceTimer);
  recompute();
}

function subscribe(listener: () => void) {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

function getSnapshot() {
  return cachedErrors;
}

function getErrorKeysSnapshot() {
  return cachedErrorKeys;
}

function getErrorMessagesSnapshot() {
  return cachedErrorMessages;
}

/** Shared validation hook — all consumers share one computation */
export function useValidation(): ValidationError[] {
  return useSyncExternalStore(subscribe, getSnapshot);
}

/** Hook that returns a Set of error keys for tree indicators */
export function useErrorKeys(): Set<string> {
  return useSyncExternalStore(subscribe, getErrorKeysSnapshot);
}

/** Hook that returns a Map from error key to error messages (for tooltips) */
export function useErrorMessages(): Map<string, string[]> {
  return useSyncExternalStore(subscribe, getErrorMessagesSnapshot);
}
