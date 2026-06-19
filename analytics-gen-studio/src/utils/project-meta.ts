// Project-file metadata: stable identity + content revision + filename helpers.
//
// `revision` is a deterministic hash of the analytics content (config + all
// files), used both for the in-studio "dirty" check and for CI/CD comparison
// of committed project files. The same algorithm is mirrored in the Dart
// `StudioGenerator` so a studio-saved file and a CI-generated file share the
// same revision for identical content.

import type { StudioState } from '../types/index.ts';

/** The analytics content that participates in the revision hash. */
export interface RevisionContent {
  config: StudioState['config'];
  eventFiles: StudioState['eventFiles'];
  sharedParamFiles: StudioState['sharedParamFiles'];
  contextFiles: StudioState['contextFiles'];
}

/** Project metadata embedded under the `meta` key of a saved project file. */
export interface ProjectMeta {
  projectId: string;
  name?: string;
  revision: string;
}

/**
 * cyrb53 — a fast, well-distributed 53-bit string hash.
 *
 * Operates on UTF-16 code units so it can be reproduced byte-for-byte in Dart
 * (`String.codeUnitAt`). All intermediate math is masked to 32 bits to match
 * `Math.imul` / `>>>` semantics across languages.
 */
export function cyrb53(str: string, seed = 0): number {
  let h1 = 0xdeadbeef ^ seed;
  let h2 = 0x41c6ce57 ^ seed;
  for (let i = 0; i < str.length; i++) {
    const ch = str.charCodeAt(i);
    h1 = Math.imul(h1 ^ ch, 2654435761);
    h2 = Math.imul(h2 ^ ch, 1597334677);
  }
  h1 = Math.imul(h1 ^ (h1 >>> 16), 2246822507);
  h1 ^= Math.imul(h2 ^ (h2 >>> 13), 3266489909);
  h2 = Math.imul(h2 ^ (h2 >>> 16), 2246822507);
  h2 ^= Math.imul(h1 ^ (h1 >>> 13), 3266489909);
  return 4294967296 * (2097151 & h2) + (h1 >>> 0);
}

/** Recursively sort object keys so the serialization is order-independent. */
function canonicalize(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(canonicalize);
  if (value && typeof value === 'object') {
    const sorted: Record<string, unknown> = {};
    for (const key of Object.keys(value as Record<string, unknown>).sort()) {
      sorted[key] = canonicalize((value as Record<string, unknown>)[key]);
    }
    return sorted;
  }
  return value;
}

/** Content revision hash — stable across key ordering, changes on any edit. */
export function computeRevision(content: RevisionContent): string {
  const canonical = JSON.stringify(canonicalize(content));
  return cyrb53(canonical).toString(16).padStart(14, '0');
}

/** Generates a stable project id (UUID v4 when available). */
export function newProjectId(): string {
  const g = globalThis.crypto;
  if (g && typeof g.randomUUID === 'function') return g.randomUUID();
  if (g && typeof g.getRandomValues === 'function') {
    const b = g.getRandomValues(new Uint8Array(16));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    const hex = Array.from(b, (x) => x.toString(16).padStart(2, '0')).join('');
    return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
  }
  return `id-${cyrb53(String(Object.keys(g ?? {}).length)).toString(16)}`;
}

/** Slugifies a project name into a filesystem-safe base, or '' when empty. */
export function slugify(name: string): string {
  return name
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 64);
}

interface NameOptions {
  /** When true, append a short content-revision suffix for uniqueness. */
  unique?: boolean;
  revision?: string;
}

function suffix({ unique, revision }: NameOptions): string {
  return unique && revision ? `-${revision.slice(0, 8)}` : '';
}

/** Derives the suggested project-file name from the project name. */
export function deriveJsonName(projectName: string, opts: NameOptions = {}): string {
  const base = slugify(projectName) || 'analytics-studio';
  return `${base}${suffix(opts)}.json`;
}

/** Derives the export ZIP name from the project name. */
export function deriveZipName(projectName: string, opts: NameOptions = {}): string {
  const base = slugify(projectName) || 'analytics-gen-config';
  return `${base}${suffix(opts)}.zip`;
}

// ── "Unique export names" preference (local, not part of the project file) ──

const UNIQUE_NAMES_KEY = 'studio-unique-export-names';

/** Whether exported file names should carry a content-hash suffix. */
export function getUniqueExportNames(): boolean {
  try {
    return localStorage.getItem(UNIQUE_NAMES_KEY) === 'true';
  } catch {
    return false;
  }
}

/** Persists the "unique export names" preference. */
export function setUniqueExportNames(value: boolean): void {
  try {
    localStorage.setItem(UNIQUE_NAMES_KEY, String(value));
  } catch {
    // Ignore storage failures (private mode / quota); the preference is non-critical.
  }
}
