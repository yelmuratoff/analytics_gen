import { useCallback, useState } from 'react';

interface InlineRenameOptions<T extends { original: string }> {
  /** Names the item cannot take; a match keeps the field open with an error. */
  takenNames: (target: T) => string[];
  apply: (target: T, newName: string) => void;
  normalize?: (target: T, name: string) => string;
}

/** Inline rename state for a tree: one item edited at a time, rejecting names already taken by its siblings. */
export function useInlineRename<T extends { original: string }>({ takenNames, apply, normalize }: InlineRenameOptions<T>) {
  const [target, setTarget] = useState<T | null>(null);
  const [value, setValueState] = useState('');
  const [error, setError] = useState<string | null>(null);

  const start = useCallback((next: T) => {
    setTarget(next);
    setValueState(next.original);
    setError(null);
  }, []);

  const cancel = useCallback(() => {
    setTarget(null);
    setError(null);
  }, []);

  const setValue = useCallback((next: string) => {
    setValueState(next);
    setError(null);
  }, []);

  const commit = () => {
    if (!target) return;
    const trimmed = value.trim();
    const name = trimmed && normalize ? normalize(target, trimmed) : trimmed;
    if (!name || name === target.original) {
      cancel();
      return;
    }
    if (takenNames(target).includes(name)) {
      setError(`"${name}" already exists`);
      return;
    }
    apply(target, name);
    cancel();
  };

  return { target, value, setValue, error, start, cancel, commit };
}
