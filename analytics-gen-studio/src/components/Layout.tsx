import { useState, useCallback, useRef } from 'react';
import Box from '@mui/material/Box';
import TabBar from './TabBar.tsx';
import Toolbar from './Toolbar.tsx';
import YamlPreview from './YamlPreview.tsx';
import ConfigTab from './config/ConfigTab.tsx';
import EventsTab from './events/EventsTab.tsx';
import SharedParamsTab from './shared/SharedParamsTab.tsx';
import ContextsTab from './contexts/ContextsTab.tsx';
import { useStore } from '../state/store.ts';
import type { LoadedSchemas } from '../schemas/loader.ts';

interface LayoutProps {
  schemas: LoadedSchemas;
}

export default function Layout({ schemas }: LayoutProps) {
  const activeTab = useStore((s) => s.activeTab);
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
      <Toolbar />
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
          {renderTab()}
        </Box>
        {/* Resize handle */}
        <Box
          role="separator"
          aria-label="Resize panels"
          onMouseDown={handleMouseDown}
          sx={{
            width: 16,
            cursor: 'col-resize',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            flexShrink: 0,
            '&:hover .resize-line': { opacity: 1, bgcolor: '#DF4926' },
          }}
        >
          <Box className="resize-line" sx={{
            width: 3,
            height: 40,
            borderRadius: 2,
            bgcolor: dragging ? '#DF4926' : 'text.disabled',
            opacity: dragging ? 1 : 0.4,
            transition: 'all 0.15s ease',
          }} />
        </Box>
        {/* YAML preview panel */}
        <Box sx={{
          flex: 1, overflow: 'hidden',
          bgcolor: '#1E1E1E',
          borderRadius: 1.5,
          display: 'flex', flexDirection: 'column',
        }}>
          <YamlPreview />
        </Box>
      </Box>
    </Box>
  );
}
