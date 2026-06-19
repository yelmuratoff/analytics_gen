import JSZip from 'jszip';
import { saveAs } from 'file-saver';
import type { EventFile, StudioState } from '../types/index.ts';
import {
  generateConfigYaml,
  generateEventFileYaml,
  generateSharedParamFileYaml,
  generateContextFileYaml,
} from './yaml-generator.ts';
import { normalizeEventDef } from './yaml-importer.ts';
import { computeRevision, type ProjectMeta } from './project-meta.ts';
import {
  saveProjectHandle,
  loadProjectHandle,
  deleteProjectHandle,
} from './file-handle-store.ts';

// ── File System Access API support ──

/** Check if File System Access API is available (Chrome/Edge) */
export const supportsFileSystemAccess = typeof window !== 'undefined' &&
  'showOpenFilePicker' in window && 'showSaveFilePicker' in window;

/** Stored file handle for "Save" without dialog */
let currentFileHandle: FileSystemFileHandle | null = null;

export function getCurrentFileName(): string | null {
  return currentFileHandle?.name ?? null;
}

export function clearFileHandle() {
  currentFileHandle = null;
  clearLastFileName();
  clearBaselineRevision();
  void deleteProjectHandle();
}

// ── Baseline revision (external-change detection) ──
//
// The content revision of the file as of our last sync (open/save). Comparing
// it against the on-disk revision tells us when the file changed underneath us
// (an external edit, a git pull, a CI regeneration) versus our own edits.

const BASELINE_REV_KEY = 'studio-file-baseline-revision';

/** Revision of the file as of our last open/save, or null. */
export function getBaselineRevision(): string | null {
  try {
    return localStorage.getItem(BASELINE_REV_KEY);
  } catch {
    return null;
  }
}

/** Records the revision we are now in sync with on disk. */
export function setBaselineRevision(revision: string): void {
  try {
    localStorage.setItem(BASELINE_REV_KEY, revision);
  } catch {
    // Ignore storage failures; degrades to no external-change detection.
  }
}

function clearBaselineRevision(): void {
  try {
    localStorage.removeItem(BASELINE_REV_KEY);
  } catch {
    // Ignore storage failures.
  }
}

/**
 * Reads the current file from disk and returns its parsed data + revision —
 * but only when read permission is already granted, so it never prompts.
 * Returns null when there is no handle, no permission, or the read fails.
 */
export async function peekDiskState(): Promise<{ data: Partial<StudioState>; revision: string; fileName: string } | null> {
  if (!currentFileHandle) return null;
  // Query only — requesting permission here would prompt without a user gesture.
  if (currentFileHandle.queryPermission &&
      (await currentFileHandle.queryPermission({ mode: 'read' })) !== 'granted') {
    return null;
  }
  try {
    const file = await currentFileHandle.getFile();
    const data = parseProject(await file.text());
    const revision = computeRevision({
      config: data.config!,
      eventFiles: data.eventFiles ?? [],
      sharedParamFiles: data.sharedParamFiles ?? [],
      contextFiles: data.contextFiles ?? [],
    });
    return { data, revision, fileName: file.name };
  } catch {
    return null;
  }
}

// ── Last file name (every browser, incl. Safari/Firefox) ──
//
// The File System Access handle is Chromium-only. To keep the "remembered
// file" UX consistent everywhere, the last opened/saved file name is also kept
// in localStorage — it drives the toolbar indicator and the Save As default.

const LAST_FILE_NAME_KEY = 'studio-last-file-name';

/** Returns the last opened/saved project file name, or null. */
export function getLastFileName(): string | null {
  try {
    return localStorage.getItem(LAST_FILE_NAME_KEY);
  } catch {
    return null;
  }
}

/** Remembers the last opened/saved project file name. */
export function setLastFileName(name: string): void {
  try {
    localStorage.setItem(LAST_FILE_NAME_KEY, name);
  } catch {
    // Ignore storage failures (private mode / quota); non-critical.
  }
}

function clearLastFileName(): void {
  try {
    localStorage.removeItem(LAST_FILE_NAME_KEY);
  } catch {
    // Ignore storage failures.
  }
}

/**
 * Reconnects to the project file remembered from a previous session.
 * Returns the file name to display, or null when nothing is remembered.
 * Does not prompt for permission — that is requested lazily on the first save.
 */
export async function restoreFileHandle(): Promise<string | null> {
  if (currentFileHandle) return currentFileHandle.name;
  if (!supportsFileSystemAccess) return null;
  const handle = await loadProjectHandle();
  if (!handle) return null;
  currentFileHandle = handle;
  return handle.name;
}

/**
 * Ensures read-write permission on the handle. Only prompts when [request] is
 * true — which must coincide with a user gesture (e.g. a Save click).
 */
async function ensureWritePermission(handle: FileSystemFileHandle, request: boolean): Promise<boolean> {
  // Legacy implementations grant access at pick time and expose no permission API.
  if (!handle.queryPermission && !handle.requestPermission) return true;
  const descriptor = { mode: 'readwrite' as const };
  if (handle.queryPermission && (await handle.queryPermission(descriptor)) === 'granted') return true;
  if (request && handle.requestPermission) {
    return (await handle.requestPermission(descriptor)) === 'granted';
  }
  return false;
}

// ── Project serialization ──

function serializeProject(state: StudioState): string {
  const content = {
    config: state.config,
    eventFiles: state.eventFiles,
    sharedParamFiles: state.sharedParamFiles,
    contextFiles: state.contextFiles,
  };
  const meta: ProjectMeta = {
    projectId: state.projectId,
    ...(state.projectName ? { name: state.projectName } : {}),
    revision: computeRevision(content),
  };
  const projectData = {
    version: 1,
    meta,
    activeTab: state.activeTab,
    ...content,
  };
  return JSON.stringify(projectData, null, 2);
}

function parseProject(text: string): Partial<StudioState> {
  const data = JSON.parse(text);
  if (!data.version || !data.config) {
    throw new Error('Invalid project file format');
  }
  if (Array.isArray(data.eventFiles)) {
    data.eventFiles = (data.eventFiles as EventFile[]).map((file) => ({
      fileName: file.fileName,
      domains: Object.fromEntries(
        Object.entries(file.domains ?? {}).map(([dn, events]) => [
          dn,
          Object.fromEntries(
            Object.entries(events ?? {})
              .map(([en, ev]) => [en, normalizeEventDef(ev)] as const)
              .filter(([, ev]) => ev !== null),
          ),
        ]),
      ),
    }));
  }
  if (data.meta && typeof data.meta === 'object') {
    if (typeof data.meta.projectId === 'string') data.projectId = data.meta.projectId;
    if (typeof data.meta.name === 'string') data.projectName = data.meta.name;
  }
  return data;
}

// ── Open ──

/**
 * Open a project file. Uses File System Access API when available
 * to remember the file handle for subsequent saves.
 * Falls back to traditional file input.
 */
export async function openProject(): Promise<{ data: Partial<StudioState>; fileName: string } | null> {
  if (supportsFileSystemAccess) {
    try {
      const [handle] = await window.showOpenFilePicker!({
        types: [{
          description: 'Studio Project',
          accept: { 'application/json': ['.json'] },
        }],
        multiple: false,
      });
      const file = await handle.getFile();
      const text = await file.text();
      const data = parseProject(text);
      currentFileHandle = handle;
      await saveProjectHandle(handle);
      return { data, fileName: file.name };
    } catch (err) {
      // User cancelled the picker
      if (err instanceof DOMException && err.name === 'AbortError') return null;
      throw err;
    }
  }
  return null; // Caller should use fallback <input>
}

/**
 * Load from a File object (fallback for non-FSAA browsers).
 */
export function loadProjectFile(file: File): Promise<Partial<StudioState>> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        resolve(parseProject(e.target?.result as string));
      } catch (err) {
        reject(err instanceof SyntaxError ? new Error('Failed to parse project file') : err);
      }
    };
    reader.onerror = () => reject(new Error('Failed to read file'));
    reader.readAsText(file);
  });
}

// ── Save ──

/**
 * Save to the current file handle (no dialog).
 * Returns true if saved, false if no handle exists.
 */
export async function saveProjectToHandle(state: StudioState): Promise<boolean> {
  if (!currentFileHandle) return false;
  // Save is a user gesture, so a permission re-prompt is allowed here. A handle
  // restored from a previous session starts in the "prompt" permission state.
  if (!(await ensureWritePermission(currentFileHandle, true))) return false;
  try {
    const writable = await currentFileHandle.createWritable();
    await writable.write(serializeProject(state));
    await writable.close();
    return true;
  } catch {
    // Handle invalidated (file moved/deleted) — forget it so we fall back to Save As.
    currentFileHandle = null;
    await deleteProjectHandle();
    return false;
  }
}

interface SaveAsOptions {
  /** File name proposed in the picker / used for the download fallback. */
  suggestedName?: string;
}

/**
 * Save As — always shows picker dialog. Updates the file handle.
 */
export async function saveProjectAs(state: StudioState, opts: SaveAsOptions = {}): Promise<string | null> {
  const suggestedName = opts.suggestedName ?? currentFileHandle?.name ?? 'analytics-studio.json';
  if (supportsFileSystemAccess) {
    try {
      const handle = await window.showSaveFilePicker!({
        suggestedName,
        types: [{
          description: 'Studio Project',
          accept: { 'application/json': ['.json'] },
        }],
      });
      const writable = await handle.createWritable();
      await writable.write(serializeProject(state));
      await writable.close();
      currentFileHandle = handle;
      await saveProjectHandle(handle);
      return handle.name;
    } catch (err) {
      if (err instanceof DOMException && err.name === 'AbortError') return null;
      throw err;
    }
  }
  // Fallback: download
  const blob = new Blob([serializeProject(state)], { type: 'application/json' });
  saveAs(blob, suggestedName);
  return suggestedName;
}

/**
 * Smart save: if file handle exists, save silently. Otherwise, Save As.
 */
export async function saveProject(state: StudioState, opts: SaveAsOptions = {}): Promise<{ saved: boolean; fileName: string | null }> {
  if (currentFileHandle) {
    const ok = await saveProjectToHandle(state);
    if (ok) return { saved: true, fileName: currentFileHandle.name };
  }
  const name = await saveProjectAs(state, opts);
  return { saved: !!name, fileName: name };
}

// ── Export ──

export function exportSingleFile(content: string, fileName: string) {
  const blob = new Blob([content], { type: 'text/yaml;charset=utf-8' });
  saveAs(blob, fileName);
}

export function exportAllAsZip(state: StudioState, opts: { zipName?: string } = {}) {
  const zip = new JSZip();

  zip.file('analytics_gen.yaml', generateConfigYaml(state.config));

  for (const file of state.eventFiles) {
    zip.file(file.fileName, generateEventFileYaml(file));
  }

  for (const file of state.sharedParamFiles) {
    zip.file(file.fileName, generateSharedParamFileYaml(file));
  }

  for (const file of state.contextFiles) {
    zip.file(file.fileName, generateContextFileYaml(file));
  }

  zip.generateAsync({ type: 'blob' }).then((blob) => {
    saveAs(blob, opts.zipName ?? 'analytics-gen-config.zip');
  });
}

// ── Clipboard ──

export function copyToClipboard(text: string): Promise<void> {
  return navigator.clipboard.writeText(text);
}
