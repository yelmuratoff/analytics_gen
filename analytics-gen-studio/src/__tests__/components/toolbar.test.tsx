import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen, fireEvent, act } from '@testing-library/react';
import { ThemeProvider } from '@mui/material/styles';
import { useStore } from '../../state/store.ts';
import { refreshValidation } from '../../hooks/useValidation.ts';
import { getTheme } from '../../theme.ts';
import { extractImportHints } from '../../utils/yaml-importer.ts';
import Toolbar from '../../components/Toolbar.tsx';
import { canonicalSchema } from '../schema-fixtures.ts';

const { exportAllAsZip } = vi.hoisted(() => ({ exportAllAsZip: vi.fn(() => Promise.resolve()) }));
vi.mock('../../utils/export.ts', async (importOriginal) => ({
  ...(await importOriginal<typeof import('../../utils/export.ts')>()),
  exportAllAsZip,
  restoreFileHandle: () => Promise.resolve(null),
  peekDiskState: () => Promise.resolve(null),
}));

const importHints = extractImportHints(
  canonicalSchema('analytics_gen.schema.json')!,
  canonicalSchema('events.schema.json')!,
  canonicalSchema('shared_parameters.schema.json')!,
);

function renderToolbar() {
  return render(
    <ThemeProvider theme={getTheme('light')}>
      <Toolbar importHints={importHints} />
    </ThemeProvider>,
  );
}

function pressExportShortcut() {
  fireEvent.keyDown(window, { key: 'e', code: 'KeyE', shiftKey: true, ctrlKey: true });
}

describe('Toolbar export', () => {
  beforeEach(() => {
    exportAllAsZip.mockClear();
    useStore.getState().resetState();
  });

  it('does not export from the shortcut while the project has validation errors', async () => {
    useStore.getState().addEventFile('empty.yaml');
    refreshValidation();
    renderToolbar();

    await act(async () => pressExportShortcut());

    expect(exportAllAsZip).not.toHaveBeenCalled();
    expect(await screen.findByText('Fix the validation errors before exporting')).toBeInTheDocument();
  });

  it('exports from the shortcut when the project is valid', async () => {
    refreshValidation();
    renderToolbar();

    await act(async () => pressExportShortcut());

    expect(exportAllAsZip).toHaveBeenCalledTimes(1);
    expect(await screen.findByText('ZIP exported')).toBeInTheDocument();
  });
});

describe('Toolbar shortcuts with Shift', () => {
  beforeEach(() => {
    exportAllAsZip.mockClear();
    useStore.getState().resetState();
    useStore.temporal.getState().clear();
    refreshValidation();
  });

  it('exports when Shift turns the key into an uppercase E', async () => {
    renderToolbar();

    await act(async () => fireEvent.keyDown(window, { key: 'E', shiftKey: true, ctrlKey: true }));

    expect(exportAllAsZip).toHaveBeenCalledTimes(1);
  });

  it('redoes when Shift turns the key into an uppercase Z', async () => {
    renderToolbar();
    act(() => useStore.getState().addEventFile('auth.yaml'));
    act(() => useStore.temporal.getState().undo());

    await act(async () => fireEvent.keyDown(window, { key: 'Z', shiftKey: true, ctrlKey: true }));

    expect(useStore.getState().eventFiles.map((f) => f.fileName)).toEqual(['auth.yaml']);
  });
});
