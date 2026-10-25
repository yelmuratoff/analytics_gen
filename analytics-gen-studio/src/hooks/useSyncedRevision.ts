import { useCallback, useMemo, useState } from 'react';
import { useShallow } from 'zustand/react/shallow';
import { useStore } from '../state/store.ts';
import { contentOf, computeRevision } from '../utils/project-meta.ts';
import { getBaselineRevision, setBaselineRevision } from '../utils/export.ts';

/** Content revision of the project and whether it differs from the last opened or saved file. */
export function useSyncedRevision() {
  const content = useStore(useShallow(contentOf));
  const revision = useMemo(() => computeRevision(content), [content]);
  const [baseline, setBaseline] = useState(getBaselineRevision);

  const markSynced = useCallback((syncedRevision: string) => {
    setBaselineRevision(syncedRevision);
    setBaseline(syncedRevision);
  }, []);

  const forgetSync = useCallback(() => setBaseline(null), []);

  return { revision, isDirty: baseline !== null && baseline !== revision, markSynced, forgetSync };
}
