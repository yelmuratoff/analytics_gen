import { useState, useCallback, useRef, useMemo, lazy, Suspense } from 'react';
import Box from '@mui/material/Box';
import CircularProgress from '@mui/material/CircularProgress';
import TabBar from './TabBar.tsx';
import Toolbar from './Toolbar.tsx';
import ResizeHandle from './ResizeHandle.tsx';
import { useStore } from '../state/store.ts';
import type { LoadedSchemas } from '../schemas/loader.ts';
import { extractImportHints } from '../utils/yaml-importer.ts';

// Lazy-load heavy tab components — only loaded when first activated
const ConfigTab = lazy(() => import('./config/ConfigTab.tsx'));
const EventsTab = lazy(() => import('./events/EventsTab.tsx'));
const SharedParamsTab = lazy(() => import('./shared/SharedParamsTab.tsx'));
const ContextsTab = lazy(() => import('./contexts/ContextsTab.tsx'));
const YamlPreview = lazy(() => import('./YamlPreview.tsx'));

interface LayoutProps {
  schemas: LoadedSchemas;
}

export default function Layout({ schemas }: LayoutProps) {
  const activeTab = useStore((s) => s.activeTab);
  const importHints = useMemo(
    () => extractImportHints(schemas.rawConfigSchema, schemas.eventsSchema, schemas.sharedParametersSchema),
    [schemas],
  );
  const [formWidth, setFormWidth] = useState(57);
  const [dragging, setDragging] = useState(false);
  const isDragging = useRef(false);
  const containerRef = useRef<HTMLDivElement>(null);

  const handleMouseDown = useCallback(() => {
    isDragging.current = true;
    setDragging(true);
    document.body.style.cursor = 'col-resize';
    document.body.style.userSelect = 'none';

    const handleMouseMove = (e: MouseEvent) => {
      if (!isDragging.current || !containerRef.current) return;
      const rect = containerRef.current.getBoundingClientRect();
      const pct = ((e.clientX - rect.left) / rect.width) * 100;
      setFormWidth(Math.max(30, Math.min(75, pct)));
    };

    const handleMouseUp = () => {
      isDragging.current = false;
      setDragging(false);
      document.body.style.cursor = '';
      document.body.style.userSelect = '';
      window.removeEventListener('mousemove', handleMouseMove);
      window.removeEventListener('mouseup', handleMouseUp);
    };

    window.addEventListener('mousemove', handleMouseMove);
    window.addEventListener('mouseup', handleMouseUp);
  }, []);

  const renderTab = () => {
    switch (activeTab) {
      case 'config':
        return <ConfigTab configSchema={schemas.configSchema} />;
      case 'events':
        return <EventsTab parameterSchema={schemas.parameterSchema} eventEditorSchema={schemas.eventEditorSchema} parameterTypes={schemas.parameterTypes} />;
      case 'shared':
        return <SharedParamsTab parameterSchema={schemas.parameterSchema} />;
      case 'contexts':
        return <ContextsTab parameterSchema={schemas.parameterSchema} operations={schemas.operations} />;
    }
  };

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', height: '100vh', bgcolor: 'background.default' }}>
      <Toolbar importHints={importHints} />
      <TabBar />
      <Box ref={containerRef} sx={{ display: 'flex', flex: 1, overflow: 'hidden', p: 2, gap: 0 }}>
        {/* Form panel */}
        <Box key={activeTab} sx={{
          flex: `0 0 ${formWidth}%`, overflow: 'auto', p: 3,
          bgcolor: 'background.paper',
          borderRadius: 1.5,
          border: 1, borderColor: 'divider',
          '@keyframes fadeSlideIn': {
            from: { opacity: 0, transform: 'translateY(4px)' },
            to: { opacity: 1, transform: 'translateY(0)' },
          },
          animation: 'fadeSlideIn 0.2s ease-out',
        }}>
          <Suspense fallback={<Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100%' }}><CircularProgress size={24} sx={{ color: '#DF4926' }} /></Box>}>{renderTab()}</Suspense>
        </Box>
        <ResizeHandle dragging={dragging} onMouseDown={handleMouseDown} />
        {/* YAML preview panel */}
        <Box sx={{
          flex: 1, overflow: 'hidden',
          bgcolor: '#1E1E1E',
          borderRadius: 1.5,
          display: 'flex', flexDirection: 'column',
        }}>
          <Suspense fallback={<Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100%' }}><CircularProgress size={20} sx={{ color: '#555' }} /></Box>}><YamlPreview /></Suspense>
        </Box>
      </Box>
    </Box>
  );
}
