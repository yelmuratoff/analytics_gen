// Runs after setup.ts (localStorage is available)
// Loads the real schemas through the Studio loader so tests run against schema-derived rules and defaults

import { vi } from 'vitest';
import { loadSchemas } from '../schemas/loader.ts';
import { applySchemaConstants } from '../schemas/constants.ts';
import { setSchemaDefaultConfig } from '../state/store.ts';
import { canonicalSchema } from './schema-fixtures.ts';

vi.stubGlobal('fetch', (url: string) => {
  const schema = canonicalSchema(url.split('/').pop() ?? '');
  if (!schema) return Promise.resolve({ ok: false, status: 404 });
  return Promise.resolve({ ok: true, json: () => Promise.resolve(schema) });
});
const loaded = await loadSchemas();
vi.unstubAllGlobals();

applySchemaConstants({ ...loaded, defaultParamType: loaded.parameterTypes[0] ?? 'string' });
setSchemaDefaultConfig(loaded.defaultConfig);
