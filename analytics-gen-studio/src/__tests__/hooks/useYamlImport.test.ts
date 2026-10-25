import { describe, it, expect, beforeEach } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useStore } from '../../state/store.ts';
import { useYamlImport } from '../../hooks/useYamlImport.ts';
import { extractImportHints, type ImportSummary } from '../../utils/yaml-importer.ts';
import { canonicalSchema } from '../schema-fixtures.ts';

const hints = extractImportHints(
  canonicalSchema('analytics_gen.schema.json')!,
  canonicalSchema('events.schema.json')!,
  canonicalSchema('shared_parameters.schema.json')!,
);

function yamlFile(name: string, content: string) {
  return new File([content], name, { type: 'text/yaml' });
}

describe('useYamlImport', () => {
  beforeEach(() => useStore.getState().resetState());

  it('imports the valid files, reports the rest, and opens the tab of the last import', async () => {
    const { result } = renderHook(() => useYamlImport(hints));
    let summary: ImportSummary | undefined;

    await act(async () => {
      summary = await result.current([
        yamlFile('broken.yaml', 'auth:\n  login:\n description: x\n   bad: [\n'),
        yamlFile('auth.yaml', 'auth:\n  login:\n    description: Login\n'),
        yamlFile('list.yaml', '- a\n- b\n'),
        yamlFile('shared.yaml', 'parameters:\n  user_id: string\n'),
      ]);
    });

    expect(summary?.imported).toBe(2);
    expect(summary?.failures.map((f) => f.fileName)).toEqual(['broken.yaml', 'list.yaml']);
    expect(summary?.failures[1].reason).toBe('unknown file type');
    expect(useStore.getState().eventFiles.map((f) => f.fileName)).toEqual(['auth.yaml']);
    expect(useStore.getState().sharedParamFiles.map((f) => f.fileName)).toEqual(['shared.yaml']);
    expect(useStore.getState().activeTab).toBe('shared');
  });

  it('merges flat config aliases into their nested sections', async () => {
    const { result } = renderHook(() => useYamlImport(hints));

    await act(async () => {
      await result.current([yamlFile('analytics_gen.yaml', 'analytics_gen:\n  events_path: tracking\n  generate_csv: true\n')]);
    });

    const { config } = useStore.getState();
    expect(config.inputs.events).toBe('tracking');
    expect(config.targets.csv).toBe(true);
    expect('events_path' in config).toBe(false);
  });
});
