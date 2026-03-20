import { useState, useCallback, useRef } from 'react';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import type { RJSFSchema } from '@rjsf/utils';
import ElectricBoltRounded from '@mui/icons-material/ElectricBoltRounded';
import { useStore } from '../../state/store.ts';
import EmptyState from '../EmptyState.tsx';
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
        <EmptyState
          icon={<ElectricBoltRounded sx={{ fontSize: 28, color: '#D5D0CB' }} />}
          title={selectedPath?.tab === 'events' ? 'Select an event or parameter' : 'Select from the tree'}
          description="Add a file, then create domains and events. Click any item to edit its properties."
        />
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
      <Box data-events-sidebar sx={{
        width: sidebarWidth, minWidth: 200, borderRight: '1px solid #EEEBE8', overflow: 'auto', flexShrink: 0,
        '&::-webkit-scrollbar': { width: 5 },
        '&::-webkit-scrollbar-thumb': { bgcolor: 'rgba(0,0,0,0.08)', borderRadius: 3 },
      }}>
        <FileTree />
      </Box>
      {/* Resize handle */}
      <Box
        role="separator"
        aria-label="Resize sidebar"
        onMouseDown={handleMouseDown}
        sx={{
          width: 12,
          cursor: 'col-resize',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          flexShrink: 0,
          '&:hover .sidebar-resize, &:active .sidebar-resize': { opacity: 0.6 },
        }}
      >
        <Box className="sidebar-resize" sx={{
          display: 'flex', flexDirection: 'column', gap: '3px',
          opacity: 0.35, transition: 'opacity 0.15s ease',
        }}>
          {[0, 1, 2, 3].map((i) => (
            <Box key={i} sx={{ display: 'flex', gap: '3px' }}>
              <Box sx={{ width: 3, height: 3, borderRadius: '50%', bgcolor: '#999' }} />
              <Box sx={{ width: 3, height: 3, borderRadius: '50%', bgcolor: '#999' }} />
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
