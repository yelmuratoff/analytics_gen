import { describe, it, expect, beforeEach } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useStore } from '../../state/store.ts';
import { clearFileHandle } from '../../utils/export.ts';
import { useSyncedRevision } from '../../hooks/useSyncedRevision.ts';

describe('useSyncedRevision', () => {
  beforeEach(() => {
    clearFileHandle();
    useStore.getState().resetState();
    useStore.temporal.getState().clear();
  });

  it('is clean while the project has never been saved or opened', () => {
    const { result } = renderHook(() => useSyncedRevision());
    act(() => useStore.getState().addEventFile('auth.yaml'));
    expect(result.current.isDirty).toBe(false);
  });

  it('becomes dirty after an edit and clean again after the edit is undone', () => {
    const { result } = renderHook(() => useSyncedRevision());
    act(() => result.current.markSynced(result.current.revision));

    act(() => useStore.getState().addEventFile('auth.yaml'));
    expect(result.current.isDirty).toBe(true);

    act(() => useStore.temporal.getState().undo());
    expect(result.current.isDirty).toBe(false);
  });

  it('stays clean when only the selection or tab changes', () => {
    const { result } = renderHook(() => useSyncedRevision());
    act(() => result.current.markSynced(result.current.revision));

    act(() => {
      useStore.getState().setActiveTab('events');
      useStore.getState().setSelectedPath({ tab: 'events', fileIndex: 0 });
    });

    expect(result.current.isDirty).toBe(false);
  });

  it('forgets the saved revision', () => {
    const { result } = renderHook(() => useSyncedRevision());
    act(() => result.current.markSynced('other-revision'));
    expect(result.current.isDirty).toBe(true);

    act(() => result.current.forgetSync());

    expect(result.current.isDirty).toBe(false);
  });
});
