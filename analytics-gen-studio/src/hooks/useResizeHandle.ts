import { useState, useCallback, useRef, useEffect } from 'react';

interface UseResizeHandleOptions {
  initialWidth: number;
  min?: number;
  max?: number;
  storageKey?: string;
  /** When 'percent', width is a percentage of the container. Default: 'px'. */
  unit?: 'px' | 'percent';
}

/**
 * Shared resize handle hook — used by EventsTab, SharedParamsTab, ContextsTab, Layout.
 * Supports rAF-throttled dragging and optional localStorage persistence.
 */
export function useResizeHandle({ initialWidth, min = 200, max = 400, storageKey, unit = 'px' }: UseResizeHandleOptions) {
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
  const [atLimit, setAtLimit] = useState(false);
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
        const rect = containerRef.current.getBoundingClientRect();
        if (unit === 'percent') {
          const pct = ((e.clientX - rect.left) / rect.width) * 100;
          const clamped = Math.max(min, Math.min(max, pct));
          setWidth(clamped);
          setAtLimit(pct <= min || pct >= max);
        } else {
          const newWidth = e.clientX - rect.left;
          const clamped = Math.max(min, Math.min(max, newWidth));
          setWidth(clamped);
          setAtLimit(newWidth <= min || newWidth >= max);
        }
      });
    };

    const handleMouseUp = () => {
      isDragging.current = false;
      setDragging(false);
      setAtLimit(false);
      cancelAnimationFrame(rafRef.current);
      document.body.style.cursor = '';
      document.body.style.userSelect = '';
      window.removeEventListener('mousemove', handleMouseMove);
      window.removeEventListener('mouseup', handleMouseUp);
    };

    window.addEventListener('mousemove', handleMouseMove);
    window.addEventListener('mouseup', handleMouseUp);
  }, [min, max, unit]);

  // Persist to localStorage on drag end
  useEffect(() => {
    if (storageKey && !dragging) {
      localStorage.setItem(storageKey, String(width));
    }
  }, [dragging, width, storageKey]);

  return { width, dragging, atLimit, containerRef, handleMouseDown };
}
