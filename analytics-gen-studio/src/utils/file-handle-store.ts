// Persists the File System Access API handle of the currently open project
// in IndexedDB so the studio can reconnect to the same file after a reload —
// without forcing the user to re-open it. Handles are structured-cloneable,
// so IndexedDB can store them directly (localStorage/JSON cannot).
//
// All access is guarded: in browsers without IndexedDB (or the File System
// Access API) every call resolves to a no-op, and the caller falls back to
// the localStorage-persisted working state.

const DB_NAME = 'analytics-gen-studio';
const DB_VERSION = 1;
const STORE_NAME = 'handles';
const HANDLE_KEY = 'currentProject';

function openDb(): Promise<IDBDatabase | null> {
  if (typeof indexedDB === 'undefined') return Promise.resolve(null);
  return new Promise((resolve) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION);
    request.onupgradeneeded = () => {
      if (!request.result.objectStoreNames.contains(STORE_NAME)) {
        request.result.createObjectStore(STORE_NAME);
      }
    };
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => resolve(null);
  });
}

function withStore<T>(
  mode: IDBTransactionMode,
  run: (store: IDBObjectStore) => IDBRequest<T>,
): Promise<T | null> {
  return openDb().then(
    (db) =>
      new Promise<T | null>((resolve) => {
        if (!db) return resolve(null);
        const tx = db.transaction(STORE_NAME, mode);
        const request = run(tx.objectStore(STORE_NAME));
        request.onsuccess = () => resolve(request.result ?? null);
        request.onerror = () => resolve(null);
        tx.oncomplete = () => db.close();
      }),
  );
}

/** Persists the project file handle for reconnection after reload. */
export async function saveProjectHandle(handle: FileSystemFileHandle): Promise<void> {
  await withStore('readwrite', (store) => store.put(handle, HANDLE_KEY));
}

/** Restores the last-known project file handle, or null if none/unsupported. */
export function loadProjectHandle(): Promise<FileSystemFileHandle | null> {
  return withStore<FileSystemFileHandle>('readonly', (store) => store.get(HANDLE_KEY));
}

/** Forgets the persisted project file handle. */
export async function deleteProjectHandle(): Promise<void> {
  await withStore('readwrite', (store) => store.delete(HANDLE_KEY));
}
