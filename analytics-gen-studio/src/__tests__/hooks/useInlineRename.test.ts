import { describe, it, expect, vi } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useInlineRename } from '../../hooks/useInlineRename.ts';
import { withYamlExtension } from '../../utils/file-names.ts';

type Target = { type: 'file' | 'param'; original: string };

function setup() {
  const apply = vi.fn();
  const { result } = renderHook(() => useInlineRename<Target>({
    takenNames: (t) => t.type === 'file' ? ['auth.yaml', 'shop.yaml'] : ['method', 'user_id'],
    normalize: (t, name) => t.type === 'file' ? withYamlExtension(name) : name,
    apply,
  }));
  return { result, apply };
}

describe('useInlineRename', () => {
  it('keeps editing and reports an error when the name is taken', () => {
    const { result, apply } = setup();
    act(() => result.current.start({ type: 'param', original: 'method' }));
    act(() => result.current.setValue('user_id'));
    act(() => result.current.commit());

    expect(apply).not.toHaveBeenCalled();
    expect(result.current.error).toBe('"user_id" already exists');
    expect(result.current.target).toEqual({ type: 'param', original: 'method' });
  });

  it('clears the error once the name changes again', () => {
    const { result } = setup();
    act(() => result.current.start({ type: 'param', original: 'method' }));
    act(() => result.current.setValue('user_id'));
    act(() => result.current.commit());
    act(() => result.current.setValue('user_ids'));

    expect(result.current.error).toBeNull();
  });

  it('applies a free, trimmed name and stops editing', () => {
    const { result, apply } = setup();
    act(() => result.current.start({ type: 'param', original: 'method' }));
    act(() => result.current.setValue('  login_method '));
    act(() => result.current.commit());

    expect(apply).toHaveBeenCalledWith({ type: 'param', original: 'method' }, 'login_method');
    expect(result.current.target).toBeNull();
  });

  it('compares file names after adding the extension', () => {
    const { result, apply } = setup();
    act(() => result.current.start({ type: 'file', original: 'auth.yaml' }));
    act(() => result.current.setValue('shop'));
    act(() => result.current.commit());

    expect(apply).not.toHaveBeenCalled();
    expect(result.current.error).toBe('"shop.yaml" already exists');
  });

  it('stops editing without applying an empty or unchanged name', () => {
    const { result, apply } = setup();
    act(() => result.current.start({ type: 'param', original: 'method' }));
    act(() => result.current.setValue('   '));
    act(() => result.current.commit());

    expect(apply).not.toHaveBeenCalled();
    expect(result.current.target).toBeNull();
  });
});
