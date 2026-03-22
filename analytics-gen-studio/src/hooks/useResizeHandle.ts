import { useState, useCallback, useRef, useEffect } from 'react';

interface UseResizeHandleOptions {
  initialWidth: number;
  min?: number;
  max?: number;
  storageKey?: string;
}

/**
 * Shared resize handle hook — used by EventsTab, SharedParamsTab, ContextsTab.
 * Supports rAF-throttled dragging and optional localStorage persistence.
 */
export function useResizeHandle({ initialWidth, min = 200, max = 400, storageKey }: UseResizeHandleOptions) {
  const [width, setWidth] = useState(() => {
    if (storageKey) {
      const stored = localStorage.getItem(storageKey);
      if (stored) {
        const n = Number(stored);
        if (!isNaN(n)) return Math.max(min, Math.min(max, n));
      }
    }
    return initialWidth;
  });
  const [dragging, setDragging] = useState(false);
  const isDragging = useRef(false);
  const containerRef = useRef<HTMLDivElement>(null);
  const rafRef = useRef(0);

  const handleMouseDown = useCallback(() => {
    isDragging.current = true;
    setDragging(true);
    document.body.style.cursor = 'col-resize';
    document.body.style.userSelect = 'none';

    const handleMouseMove = (e: MouseEvent) => {
      if (!isDragging.current || !containerRef.current) return;
      cancelAnimationFrame(rafRef.current);
      rafRef.current = requestAnimationFrame(() => {
        if (!containerRef.current) return;
        const newWidth = e.clientX - containerRef.current.getBoundingClientRect().left;
        setWidth(Math.max(min, Math.min(max, newWidth)));
      });
    };

    const handleMouseUp = () => {
      isDragging.current = false;
      setDragging(false);
      cancelAnimationFrame(rafRef.current);
      document.body.style.cursor = '';
      document.body.style.userSelect = '';
      window.removeEventListener('mousemove', handleMouseMove);
      window.removeEventListener('mouseup', handleMouseUp);
    };

    window.addEventListener('mousemove', handleMouseMove);
    window.addEventListener('mouseup', handleMouseUp);
  }, [min, max]);

  // Persist to localStorage on drag end
  useEffect(() => {
    if (storageKey && !dragging) {
      localStorage.setItem(storageKey, String(width));
    }
  }, [dragging, width, storageKey]);

  return { width, dragging, containerRef, handleMouseDown };
}
