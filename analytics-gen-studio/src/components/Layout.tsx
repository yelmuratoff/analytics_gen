import { useState, useMemo, lazy, Suspense } from 'react';
import Box from '@mui/material/Box';
import IconButton from '@mui/material/IconButton';
import Tooltip from '@mui/material/Tooltip';
import CircularProgress from '@mui/material/CircularProgress';
import useMediaQuery from '@mui/material/useMediaQuery';
import CodeRounded from '@mui/icons-material/CodeRounded';
import CodeOffRounded from '@mui/icons-material/CodeOffRounded';
import TabBar from './TabBar.tsx';
import Toolbar from './Toolbar.tsx';
import ResizeHandle from './ResizeHandle.tsx';
import { useStore } from '../state/store.ts';
import { useResizeHandle } from '../hooks/useResizeHandle.ts';
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
  const { width: formWidth, dragging, containerRef, handleMouseDown } = useResizeHandle({
    initialWidth: 57, min: 30, max: 75, storageKey: 'studio-form-width', unit: 'percent',
  });
  const isNarrow = useMediaQuery('(max-width:1024px)');
  const [showPreview, setShowPreview] = useState(true);

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

  const previewVisible = !isNarrow || showPreview;
  const formVisible = !isNarrow || !showPreview;

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', height: '100vh', bgcolor: 'background.default' }}>
      <Toolbar importHints={importHints} />
      <TabBar>
        {isNarrow && (
          <Tooltip title={showPreview ? 'Show editor' : 'Show YAML preview'} arrow>
            <IconButton size="small" onClick={() => setShowPreview((v) => !v)} sx={{
              color: 'text.secondary', ml: 'auto',
              '&:hover': { color: '#DF4926', bgcolor: 'rgba(223,73,38,0.04)' },
            }}>
              {showPreview ? <CodeOffRounded sx={{ fontSize: 20 }} /> : <CodeRounded sx={{ fontSize: 20 }} />}
            </IconButton>
          </Tooltip>
        )}
      </TabBar>
      <Box ref={containerRef} sx={{ display: 'flex', flex: 1, overflow: 'hidden', p: 2, gap: 0 }}>
        {/* Form panel */}
        {formVisible && (
          <Box key={activeTab} sx={{
            flex: isNarrow ? 1 : `0 0 ${formWidth}%`, overflow: 'auto', p: 3,
            bgcolor: 'background.paper',
            borderRadius: 1.5,
            border: 1, borderColor: 'divider',
          }}>
            <Suspense fallback={<Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100%' }}><CircularProgress size={24} sx={{ color: '#DF4926' }} /></Box>}>{renderTab()}</Suspense>
          </Box>
        )}
        {!isNarrow && <ResizeHandle dragging={dragging} onMouseDown={handleMouseDown} />}
        {/* YAML preview panel */}
        {previewVisible && (
          <Box sx={{
            flex: 1, overflow: 'hidden',
            bgcolor: '#1E1E1E',
            borderRadius: 1.5,
            display: 'flex', flexDirection: 'column',
          }}>
            <Suspense fallback={<Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100%' }}><CircularProgress size={20} sx={{ color: '#555' }} /></Box>}><YamlPreview /></Suspense>
          </Box>
        )}
      </Box>
    </Box>
  );
}
