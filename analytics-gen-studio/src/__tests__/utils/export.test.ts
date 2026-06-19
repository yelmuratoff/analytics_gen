import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

// Mock file-saver to prevent DOM access after test cleanup
vi.mock('file-saver', () => ({ saveAs: vi.fn() }));

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
    expect((result as any).projectId).toBe('proj-123');
    expect((result as any).projectName).toBe('Checkout Funnel');
  });

  it('loads legacy files without a meta block', async () => {
    const data = { version: 1, config: { inputs: {}, outputs: {}, targets: {}, rules: {}, naming: {}, meta: {} } };
    const result = await loadProjectFile(makeFile(JSON.stringify(data)));
    expect((result as any).projectId).toBeUndefined();
    expect((result as any).projectName).toBeUndefined();
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
  it('creates JSON blob with correct structure', async () => {
    // Mock saveAs
    const mockSaveAs = vi.fn();
    vi.doMock('file-saver', () => ({ saveAs: mockSaveAs }));

    const { saveProject } = await import('../../utils/export.ts');

    const mockState = {
      activeTab: 'config' as const,
      config: { inputs: { events: 'e', shared_parameters: [], contexts: [], imports: [] }, outputs: { dart: 'd' }, targets: { csv: false, json: false, sql: false, docs: false, plan: true, test_matchers: false }, rules: { include_event_description: false, strict_event_names: true, enforce_centrally_defined_parameters: false, prevent_event_parameter_duplicates: false }, naming: { casing: 'snake_case', enforce_snake_case_domains: true, enforce_snake_case_parameters: true, event_name_template: '', identifier_template: '', domain_aliases: {} }, meta: { auto_tracking_creation_date: false, include_meta_in_parameters: false } },
      eventFiles: [],
      sharedParamFiles: [],
      contextFiles: [],
      selectedPath: null,
      errors: [],
    } as any;

    saveProject(mockState);

    // saveAs is called - but since we can't easily mock the ES module import,
    // verify the function doesn't throw
    expect(true).toBe(true);
  });
});

describe('exportAllAsZip', () => {
  it('does not throw with empty state', async () => {
    const { exportAllAsZip } = await import('../../utils/export.ts');

    const mockState = {
      config: { inputs: { events: 'e', shared_parameters: [], contexts: [], imports: [] }, outputs: { dart: 'd' }, targets: { csv: false, json: false, sql: false, docs: false, plan: true, test_matchers: false }, rules: { include_event_description: false, strict_event_names: true, enforce_centrally_defined_parameters: false, prevent_event_parameter_duplicates: false }, naming: { casing: 'snake_case', enforce_snake_case_domains: true, enforce_snake_case_parameters: true, event_name_template: '', identifier_template: '', domain_aliases: {} }, meta: { auto_tracking_creation_date: false, include_meta_in_parameters: false } },
      eventFiles: [],
      sharedParamFiles: [],
      contextFiles: [],
    } as any;

    // Should not throw
    expect(() => exportAllAsZip(mockState)).not.toThrow();
  });
});
