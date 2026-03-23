import { useState, useMemo, useRef, useEffect, useCallback, lazy, Suspense } from 'react';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import IconButton from '@mui/material/IconButton';
import Tooltip from '@mui/material/Tooltip';
import CircularProgress from '@mui/material/CircularProgress';
import Snackbar from '@mui/material/Snackbar';
import Alert from '@mui/material/Alert';
import Fade from '@mui/material/Fade';
import useMediaQuery from '@mui/material/useMediaQuery';
import CodeRounded from '@mui/icons-material/CodeRounded';
import CodeOffRounded from '@mui/icons-material/CodeOffRounded';
import Button from '@mui/material/Button';
import UploadFileRounded from '@mui/icons-material/UploadFileRounded';
import ElectricBoltRounded from '@mui/icons-material/ElectricBoltRounded';
import TabBar from './TabBar.tsx';
import Toolbar from './Toolbar.tsx';
import ResizeHandle from './ResizeHandle.tsx';
import { useStore } from '../state/store.ts';
import { useResizeHandle } from '../hooks/useResizeHandle.ts';
import type { LoadedSchemas } from '../schemas/loader.ts';
import { extractImportHints, importYamlString, type ImportSchemaHints } from '../utils/yaml-importer.ts';

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
  const { width: formWidth, dragging, atLimit, containerRef, handleMouseDown } = useResizeHandle({
    initialWidth: 57, min: 30, max: 75, storageKey: 'studio-form-width', unit: 'percent',
  });
  const isNarrow = useMediaQuery('(max-width:1024px)');
  const [showPreview, setShowPreview] = useState(true);

  // Reset scroll position on tab change instead of remounting with key={activeTab}
  const formRef = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (formRef.current) formRef.current.scrollTop = 0;
  }, [activeTab]);

  // ── Drag & drop import ──
  const [dragOver, setDragOver] = useState(false);
  const [dropSnackbar, setDropSnackbar] = useState<{ message: string; severity: 'success' | 'error' } | null>(null);
  const dragCounter = useRef(0);

  const eventFiles = useStore((s) => s.eventFiles);
  const sharedParamFiles = useStore((s) => s.sharedParamFiles);
  const contextFiles = useStore((s) => s.contextFiles);
  const importEventFile = useStore((s) => s.importEventFile);
  const importSharedParamFile = useStore((s) => s.importSharedParamFile);
  const importContextFile = useStore((s) => s.importContextFile);
  const mergeConfig = useStore((s) => s.mergeConfig);
  const setActiveTab = useStore((s) => s.setActiveTab);
  const addEventFile = useStore((s) => s.addEventFile);
  const addDomain = useStore((s) => s.addDomain);

  const isEmpty = eventFiles.length === 0 && sharedParamFiles.length === 0 && contextFiles.length === 0;

  const handleDragEnter = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    dragCounter.current++;
    if (e.dataTransfer.types.includes('Files')) setDragOver(true);
  }, []);
  const handleDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    dragCounter.current--;
    if (dragCounter.current === 0) setDragOver(false);
  }, []);
  const handleDragOver = useCallback((e: React.DragEvent) => { e.preventDefault(); }, []);
  const handleDrop = useCallback(async (e: React.DragEvent) => {
    e.preventDefault();
    dragCounter.current = 0;
    setDragOver(false);
    const files = Array.from(e.dataTransfer.files).filter(
      (f) => f.name.endsWith('.yaml') || f.name.endsWith('.yml'),
    );
    if (files.length === 0) {
      setDropSnackbar({ message: 'Only .yaml / .yml files can be imported', severity: 'error' });
      return;
    }
    let imported = 0;
    let lastType = '';
    for (const file of files) {
      try {
        const content = await file.text();
        const result = importYamlString(content, file.name, importHints);
        if (!result) continue;
        switch (result.type) {
          case 'events': if (result.eventFile) importEventFile(result.eventFile); lastType = 'events'; break;
          case 'shared': if (result.sharedFile) importSharedParamFile(result.sharedFile); lastType = 'shared'; break;
          case 'context': if (result.contextFile) importContextFile(result.contextFile); lastType = 'contexts'; break;
          case 'config': if (result.config) mergeConfig(result.config); lastType = 'config'; break;
        }
        imported++;
      } catch { /* skip malformed files */ }
    }
    if (imported > 0) {
      setDropSnackbar({ message: `Imported ${imported} file${imported > 1 ? 's' : ''}`, severity: 'success' });
      if (lastType) setActiveTab(lastType as 'config' | 'events' | 'shared' | 'contexts');
    } else {
      setDropSnackbar({ message: 'Could not detect YAML type', severity: 'error' });
    }
  }, [importHints, importEventFile, importSharedParamFile, importContextFile, mergeConfig, setActiveTab]);

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
    <Box
      sx={{ display: 'flex', flexDirection: 'column', height: '100vh', bgcolor: 'background.default', position: 'relative' }}
      onDragEnter={handleDragEnter}
      onDragLeave={handleDragLeave}
      onDragOver={handleDragOver}
      onDrop={handleDrop}
    >
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
          <Box ref={formRef} sx={{
            flex: isNarrow ? 1 : `0 0 ${formWidth}%`, overflow: 'auto', p: 3,
            bgcolor: 'background.paper',
            borderRadius: 1.5,
            border: 1, borderColor: 'divider',
          }}>
            {isEmpty && activeTab === 'config' && (
              <Box sx={{
                mb: 3, p: 3, borderRadius: 2,
                border: '1px dashed', borderColor: 'divider',
                bgcolor: 'action.hover',
                textAlign: 'center',
              }}>
                <Box sx={{
                  width: 56, height: 56, borderRadius: '50%', mx: 'auto', mb: 1.5,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  bgcolor: 'rgba(223,73,38,0.08)', border: '2px solid rgba(223,73,38,0.2)',
                }}>
                  <ElectricBoltRounded sx={{ fontSize: 26, color: '#DF4926' }} />
                </Box>
                <Typography sx={{ fontWeight: 700, fontSize: '0.95rem', mb: 0.5, color: 'text.primary' }}>
                  Welcome to Analytics Gen Studio
                </Typography>
                <Typography sx={{ fontSize: '0.82rem', color: 'text.secondary', mb: 2, lineHeight: 1.6, maxWidth: 380, mx: 'auto' }}>
                  Configure your project below, then create events or drag & drop existing YAML files to get started.
                </Typography>
                <Box sx={{ display: 'flex', gap: 1.5, justifyContent: 'center', flexWrap: 'wrap' }}>
                  <Button
                    variant="contained"
                    size="small"
                    startIcon={<ElectricBoltRounded sx={{ fontSize: 16 }} />}
                    onClick={() => {
                      setActiveTab('events');
                      addEventFile('events.yaml');
                      addDomain(0, 'app');
                    }}
                    sx={{ fontSize: '0.82rem' }}
                  >
                    Create first event
                  </Button>
                  <Button
                    variant="outlined"
                    size="small"
                    startIcon={<UploadFileRounded sx={{ fontSize: 16 }} />}
                    onClick={() => {
                      const input = document.createElement('input');
                      input.type = 'file';
                      input.accept = '.yaml,.yml';
                      input.multiple = true;
                      input.onchange = async () => {
                        if (!input.files) return;
                        let count = 0;
                        let lastType = '';
                        for (const file of Array.from(input.files)) {
                          try {
                            const content = await file.text();
                            const result = importYamlString(content, file.name, importHints);
                            if (!result) continue;
                            switch (result.type) {
                              case 'events': if (result.eventFile) importEventFile(result.eventFile); lastType = 'events'; break;
                              case 'shared': if (result.sharedFile) importSharedParamFile(result.sharedFile); lastType = 'shared'; break;
                              case 'context': if (result.contextFile) importContextFile(result.contextFile); lastType = 'contexts'; break;
                              case 'config': if (result.config) mergeConfig(result.config); lastType = 'config'; break;
                            }
                            count++;
                          } catch { /* skip */ }
                        }
                        if (count > 0 && lastType) setActiveTab(lastType as 'config' | 'events' | 'shared' | 'contexts');
                      };
                      input.click();
                    }}
                    sx={{ fontSize: '0.82rem', borderColor: 'divider', color: 'text.secondary', '&:hover': { color: '#DF4926', borderColor: '#DF4926' } }}
                  >
                    Import YAML
                  </Button>
                </Box>
              </Box>
            )}
            <Suspense fallback={<Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100%' }}><CircularProgress size={24} sx={{ color: '#DF4926' }} /></Box>}>{renderTab()}</Suspense>
          </Box>
        )}
        {!isNarrow && <ResizeHandle dragging={dragging} atLimit={atLimit} onMouseDown={handleMouseDown} />}
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

      {/* Drag & drop overlay */}
      <Fade in={dragOver}>
        <Box sx={{
          position: 'absolute', inset: 0, zIndex: 9999,
          display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 1.5,
          bgcolor: 'rgba(0,0,0,0.5)', backdropFilter: 'blur(4px)',
          pointerEvents: 'none',
        }}>
          <Box sx={{
            width: 80, height: 80, borderRadius: '50%',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            bgcolor: 'rgba(223,73,38,0.15)', border: '2px dashed #DF4926',
          }}>
            <UploadFileRounded sx={{ fontSize: 36, color: '#DF4926' }} />
          </Box>
          <Typography sx={{ color: '#fff', fontWeight: 600, fontSize: '1rem' }}>
            Drop YAML files to import
          </Typography>
          <Typography sx={{ color: 'rgba(255,255,255,0.6)', fontSize: '0.82rem' }}>
            Events, shared params, contexts, or config files
          </Typography>
        </Box>
      </Fade>

      <Snackbar
        open={!!dropSnackbar}
        autoHideDuration={dropSnackbar?.severity === 'error' ? 6000 : 2500}
        onClose={() => setDropSnackbar(null)}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        {dropSnackbar ? (
          <Alert onClose={() => setDropSnackbar(null)} severity={dropSnackbar.severity} variant="filled"
            sx={{ borderRadius: 2, minWidth: 200 }}>
            {dropSnackbar.message}
          </Alert>
        ) : undefined}
      </Snackbar>
    </Box>
  );
}
