import { describe, it, expect, vi, beforeEach } from 'vitest';

// Mock FileReader since it's not available in Node test env
class MockFileReader {
  result: string | null = null;
  onload: ((e: any) => void) | null = null;
  onerror: (() => void) | null = null;
  readAsText(file: File) {
    file.text().then((text) => {
      this.result = text;
      this.onload?.({ target: { result: text } });
    });
  }
}
vi.stubGlobal('FileReader', MockFileReader);

import { loadProjectFile } from '../../utils/export.ts';

function makeFile(content: string): File {
  return new File([content], 'test.json', { type: 'application/json' });
}

describe('loadProjectFile', () => {
  it('parses valid project JSON', async () => {
    const data = { version: 1, config: { inputs: {}, outputs: {}, targets: {}, rules: {}, naming: {}, meta: {} }, eventFiles: [], sharedParamFiles: [], contextFiles: [] };
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

  it('accepts JSON with extra fields', async () => {
    const data = { version: 2, config: {}, futureField: 'hello' };
    const result = await loadProjectFile(makeFile(JSON.stringify(data)));
    expect(result).toBeDefined();
  });

  it('preserves all data fields', async () => {
    const data = {
      version: 1,
      activeTab: 'events',
      config: { inputs: { events: 'e' }, outputs: { dart: 'd' }, targets: {}, rules: {}, naming: {}, meta: {} },
      eventFiles: [{ fileName: 'a.yaml', domains: {} }],
      sharedParamFiles: [{ fileName: 's.yaml', parameters: { sid: 'string' } }],
      contextFiles: [{ fileName: 'c.yaml', contextName: 'ctx', properties: {} }],
    };
    const result = await loadProjectFile(makeFile(JSON.stringify(data)));
    expect(result.activeTab).toBe('events');
    expect((result as any).eventFiles?.[0]?.fileName).toBe('a.yaml');
    expect((result as any).sharedParamFiles?.[0]?.parameters?.sid).toBe('string');
    expect((result as any).contextFiles?.[0]?.contextName).toBe('ctx');
  });
});

describe('copyToClipboard', () => {
  it('calls navigator.clipboard.writeText', async () => {
    const writeText = vi.fn().mockResolvedValue(undefined);
    Object.assign(navigator, { clipboard: { writeText } });
    const { copyToClipboard } = await import('../../utils/export.ts');
    await copyToClipboard('test content');
    expect(writeText).toHaveBeenCalledWith('test content');
  });
});
