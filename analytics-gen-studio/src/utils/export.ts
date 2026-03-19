import JSZip from 'jszip';
import { saveAs } from 'file-saver';
import type { StudioState } from '../types/index.ts';
import {
  generateConfigYaml,
  generateEventFileYaml,
  generateSharedParamFileYaml,
  generateContextFileYaml,
} from './yaml-generator.ts';

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
}

// ── Project serialization ──

function serializeProject(state: StudioState): string {
  const projectData = {
    version: 1,
    activeTab: state.activeTab,
    config: state.config,
    eventFiles: state.eventFiles,
    sharedParamFiles: state.sharedParamFiles,
    contextFiles: state.contextFiles,
  };
  return JSON.stringify(projectData, null, 2);
}

function parseProject(text: string): Partial<StudioState> {
  const data = JSON.parse(text);
  if (!data.version || !data.config) {
    throw new Error('Invalid project file format');
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
      } catch {
        reject(new Error('Failed to parse project file'));
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
  try {
    const writable = await currentFileHandle.createWritable();
    await writable.write(serializeProject(state));
    await writable.close();
    return true;
  } catch {
    // Permission denied or handle invalidated
    currentFileHandle = null;
    return false;
  }
}

/**
 * Save As — always shows picker dialog. Updates the file handle.
 */
export async function saveProjectAs(state: StudioState): Promise<string | null> {
  if (supportsFileSystemAccess) {
    try {
      const handle = await window.showSaveFilePicker!({
        suggestedName: currentFileHandle?.name ?? 'analytics-studio.json',
        types: [{
          description: 'Studio Project',
          accept: { 'application/json': ['.json'] },
        }],
      });
      const writable = await handle.createWritable();
      await writable.write(serializeProject(state));
      await writable.close();
      currentFileHandle = handle;
      return handle.name;
    } catch (err) {
      if (err instanceof DOMException && err.name === 'AbortError') return null;
      throw err;
    }
  }
  // Fallback: download
  const blob = new Blob([serializeProject(state)], { type: 'application/json' });
  saveAs(blob, 'analytics-studio.json');
  return 'analytics-studio.json';
}

/**
 * Smart save: if file handle exists, save silently. Otherwise, Save As.
 */
export async function saveProject(state: StudioState): Promise<{ saved: boolean; fileName: string | null }> {
  if (currentFileHandle) {
    const ok = await saveProjectToHandle(state);
    if (ok) return { saved: true, fileName: currentFileHandle.name };
  }
  const name = await saveProjectAs(state);
  return { saved: !!name, fileName: name };
}

// ── Export ──

export function exportSingleFile(content: string, fileName: string) {
  const blob = new Blob([content], { type: 'text/yaml;charset=utf-8' });
  saveAs(blob, fileName);
}

export function exportAllAsZip(state: StudioState) {
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
    saveAs(blob, 'analytics-gen-config.zip');
  });
}

// ── Clipboard ──

export function copyToClipboard(text: string): Promise<void> {
  return navigator.clipboard.writeText(text);
}
