import { describe, it, expect, vi, afterEach } from 'vitest';

// Mock file-saver to prevent DOM access after test cleanup
const { saveAs } = vi.hoisted(() => ({ saveAs: vi.fn() }));
vi.mock('file-saver', () => ({ saveAs }));

// Mock FileReader since it's not available in Node test env
class MockFileReader {
  result: string | null = null;
  onload: ((e: { target: { result: string } }) => void) | null = null;
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

afterEach(() => {
  vi.restoreAllMocks();
  vi.useRealTimers();
});

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

  it('maps meta.projectId and meta.name into project state', async () => {
    const data = {
      version: 1,
      meta: { projectId: 'proj-123', name: 'Checkout Funnel', revision: 'abc' },
      config: { inputs: {}, outputs: {}, targets: {}, rules: {}, naming: {}, meta: {} },
    };
    const result = await loadProjectFile(makeFile(JSON.stringify(data)));
    expect(result.projectId).toBe('proj-123');
    expect(result.projectName).toBe('Checkout Funnel');
  });

  it('loads legacy files without a meta block', async () => {
    const data = { version: 1, config: { inputs: {}, outputs: {}, targets: {}, rules: {}, naming: {}, meta: {} } };
    const result = await loadProjectFile(makeFile(JSON.stringify(data)));
    expect(result.projectId).toBeUndefined();
    expect(result.projectName).toBeUndefined();
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
    expect(result.eventFiles?.[0]?.fileName).toBe('a.yaml');
    expect(result.sharedParamFiles?.[0]?.parameters?.sid).toBe('string');
    expect(result.contextFiles?.[0]?.contextName).toBe('ctx');
  });
});

describe('external-change detection', () => {
  it('round-trips the baseline revision through storage', async () => {
    const { getBaselineRevision, setBaselineRevision } = await import('../../utils/export.ts');
    setBaselineRevision('rev-abc');
    expect(getBaselineRevision()).toBe('rev-abc');
  });

  it('clears the baseline on clearFileHandle', async () => {
    const { getBaselineRevision, setBaselineRevision, clearFileHandle } = await import('../../utils/export.ts');
    setBaselineRevision('rev-xyz');
    clearFileHandle();
    expect(getBaselineRevision()).toBeNull();
  });

  it('peekDiskState returns null when no file is open', async () => {
    const { peekDiskState } = await import('../../utils/export.ts');
    expect(await peekDiskState()).toBeNull();
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

describe('saveProject', () => {
  it('downloads the project with its meta block when no file is open', async () => {
    const { saveProject, clearFileHandle } = await import('../../utils/export.ts');
    const { useStore } = await import('../../state/store.ts');
    clearFileHandle();
    saveAs.mockClear();
    useStore.getState().resetState();
    useStore.getState().setProjectName('Checkout Funnel');
    useStore.getState().addEventFile('auth.yaml');

    const result = await saveProject(useStore.getState(), { suggestedName: 'checkout.json' });

    expect(result).toEqual({ saved: true, fileName: 'checkout.json' });
    const [blob, name] = saveAs.mock.calls[0];
    expect(name).toBe('checkout.json');
    const saved = JSON.parse(new TextDecoder().decode(await (blob as Blob).arrayBuffer()));
    expect(saved.meta).toMatchObject({ projectId: useStore.getState().projectId, name: 'Checkout Funnel' });
    expect(saved.eventFiles).toEqual([{ fileName: 'auth.yaml', domains: {} }]);
  });
});

describe('exportAllAsZip', () => {
  it('saves one ZIP with the config and every project file after it is built', async () => {
    const JSZip = (await import('jszip')).default;
    const { exportAllAsZip } = await import('../../utils/export.ts');
    const { useStore } = await import('../../state/store.ts');
    saveAs.mockClear();
    useStore.getState().resetState();
    useStore.getState().addEventFile('auth.yaml');
    useStore.getState().addSharedParamFile('shared.yaml');
    useStore.getState().addContextFile('user.yaml', 'user');

    await exportAllAsZip(useStore.getState(), { zipName: 'project.zip' });

    expect(saveAs).toHaveBeenCalledTimes(1);
    const [blob, name] = saveAs.mock.calls[0];
    expect(name).toBe('project.zip');
    const zip = await JSZip.loadAsync(await (blob as Blob).arrayBuffer());
    expect(Object.keys(zip.files)).toEqual(['analytics_gen.yaml', 'auth.yaml', 'shared.yaml', 'user.yaml']);
  });
});
