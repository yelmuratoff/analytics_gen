import { describe, it, expect } from 'vitest';
import { loadProjectFile } from '../../utils/export.ts';

describe('loadProjectFile', () => {
  function makeFile(content: string, name = 'test.json'): File {
    return new File([content], name, { type: 'application/json' });
  }

  it('parses valid project JSON', async () => {
    const data = {
      version: 1,
      config: { inputs: { events: 'events', shared_parameters: [], contexts: [], imports: [] }, outputs: { dart: 'lib' }, targets: {}, rules: {}, naming: {}, meta: {} },
      eventFiles: [],
      sharedParamFiles: [],
      contextFiles: [],
    };
    const result = await loadProjectFile(makeFile(JSON.stringify(data)));
    expect(result.config).toBeDefined();
    expect(result.eventFiles).toEqual([]);
  });

  it('rejects invalid JSON', async () => {
    await expect(loadProjectFile(makeFile('not json'))).rejects.toThrow('Failed to parse');
  });

  it('rejects JSON without version', async () => {
    await expect(loadProjectFile(makeFile(JSON.stringify({ config: {} })))).rejects.toThrow('Invalid project file');
  });

  it('rejects JSON without config', async () => {
    await expect(loadProjectFile(makeFile(JSON.stringify({ version: 1 })))).rejects.toThrow('Invalid project file');
  });
});
