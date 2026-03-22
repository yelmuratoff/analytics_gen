import { useState, useCallback, useRef, useTransition, useEffect } from 'react';

const DEBOUNCE_MS = 200;

/**
 * Shared debounced search hook — used by FileTree, SharedParamsTab, ContextsTab.
 * Returns the raw input value, debounced search query, pending state, and a change handler.
 */
export function useDebouncedSearch() {
  const [isPending, startTransition] = useTransition();
  const [searchInput, setSearchInput] = useState('');
  const [search, setSearch] = useState('');
  const timerRef = useRef<ReturnType<typeof setTimeout>>(undefined);

  const handleSearchChange = useCallback((val: string) => {
    setSearchInput(val);
    clearTimeout(timerRef.current);
    timerRef.current = setTimeout(() => startTransition(() => setSearch(val)), DEBOUNCE_MS);
  }, [startTransition]);

  useEffect(() => () => clearTimeout(timerRef.current), []);

  return { searchInput, search, isPending, handleSearchChange } as const;
}
