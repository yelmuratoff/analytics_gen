import { useState, useCallback, useRef } from 'react';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import type { RJSFSchema } from '@rjsf/utils';
import ElectricBoltRounded from '@mui/icons-material/ElectricBoltRounded';
import { useStore } from '../../state/store.ts';
import FileTree from './FileTree.tsx';
import EventEditor from './EventEditor.tsx';
import ParameterEditor from './ParameterEditor.tsx';

interface EventsTabProps {
  parameterSchema: RJSFSchema;
  eventEditorSchema: RJSFSchema;
  parameterTypes: string[];
}

export default function EventsTab({ parameterSchema, eventEditorSchema, parameterTypes }: EventsTabProps) {
  const selectedPath = useStore((s) => s.selectedPath);
  const files = useStore((s) => s.eventFiles);
  const [sidebarWidth, setSidebarWidth] = useState(260);
  const isDragging = useRef(false);

  const handleMouseDown = useCallback(() => {
    isDragging.current = true;
    document.body.style.cursor = 'col-resize';
    document.body.style.userSelect = 'none';

    const handleMouseMove = (e: MouseEvent) => {
      if (!isDragging.current) return;
      const newWidth = e.clientX - (document.querySelector('[data-events-sidebar]') as HTMLElement)?.getBoundingClientRect().left;
      if (newWidth) setSidebarWidth(Math.max(200, Math.min(400, newWidth)));
    };

    const handleMouseUp = () => {
      isDragging.current = false;
      document.body.style.cursor = '';
      document.body.style.userSelect = '';
      window.removeEventListener('mousemove', handleMouseMove);
      window.removeEventListener('mouseup', handleMouseUp);
    };

    window.addEventListener('mousemove', handleMouseMove);
    window.addEventListener('mouseup', handleMouseUp);
  }, []);

  // Build breadcrumb from selectedPath
  const breadcrumb = (() => {
    if (!selectedPath || selectedPath.tab !== 'events' || !selectedPath.event) return null;
    const file = files[selectedPath.fileIndex];
    if (!file) return null;
    const parts = [file.fileName, selectedPath.domain, selectedPath.event];
    if (selectedPath.parameter) parts.push(selectedPath.parameter);
    return parts.filter(Boolean) as string[];
  })();

  const renderEditor = () => {
    if (!selectedPath || selectedPath.tab !== 'events' || !selectedPath.event) {
      return (
        <Box sx={{
          display: 'flex', flexDirection: 'column', alignItems: 'center',
          justifyContent: 'center', height: '100%',
        }}>
          <ElectricBoltRounded sx={{ fontSize: 36, color: '#E8E4E0', mb: 1 }} />
          <Typography sx={{ fontSize: '0.82rem', color: '#BCBCBC' }}>
            {selectedPath?.tab === 'events' ? 'Select an event or parameter' : 'Select from the tree'}
          </Typography>
        </Box>
      );
    }

    if (selectedPath.parameter) {
      return (
        <ParameterEditor
          fileIndex={selectedPath.fileIndex}
          domain={selectedPath.domain!}
          eventName={selectedPath.event}
          paramName={selectedPath.parameter}
          parameterSchema={parameterSchema}
          parameterTypes={parameterTypes}
          breadcrumb={breadcrumb}
        />
      );
    }

    return (
      <EventEditor
        fileIndex={selectedPath.fileIndex}
        domain={selectedPath.domain!}
        eventName={selectedPath.event}
        eventEditorSchema={eventEditorSchema}
        breadcrumb={breadcrumb}
      />
    );
  };

  return (
    <Box sx={{ display: 'flex', height: '100%', mx: -3, mt: -1 }}>
      <Box data-events-sidebar sx={{ width: sidebarWidth, minWidth: 200, borderRight: '1px solid #EEEBE8', overflow: 'auto', flexShrink: 0 }}>
        <FileTree />
      </Box>
      {/* Resize handle */}
      <Box
        onMouseDown={handleMouseDown}
        sx={{
          width: 12,
          cursor: 'col-resize',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          flexShrink: 0,
          '&:hover .sidebar-resize, &:active .sidebar-resize': { opacity: 0.5 },
        }}
      >
        <Box className="sidebar-resize" sx={{
          display: 'flex', flexDirection: 'column', gap: '3px',
          opacity: 0.2, transition: 'opacity 0.15s ease',
        }}>
          {[0, 1, 2, 3].map((i) => (
            <Box key={i} sx={{ display: 'flex', gap: '2px' }}>
              <Box sx={{ width: 2, height: 2, borderRadius: '50%', bgcolor: '#999' }} />
              <Box sx={{ width: 2, height: 2, borderRadius: '50%', bgcolor: '#999' }} />
            </Box>
          ))}
        </Box>
      </Box>
      <Box sx={{ flex: 1, overflow: 'auto', p: 3 }}>
        {renderEditor()}
      </Box>
    </Box>
  );
}
