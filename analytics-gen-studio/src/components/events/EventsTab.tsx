import { useState, useCallback, useRef } from 'react';
import Box from '@mui/material/Box';
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
  const [dragging, setDragging] = useState(false);
  const isDragging = useRef(false);

  const handleMouseDown = useCallback(() => {
    isDragging.current = true;
    setDragging(true);
    document.body.style.cursor = 'col-resize';
    document.body.style.userSelect = 'none';

    const handleMouseMove = (e: MouseEvent) => {
      if (!isDragging.current) return;
      const newWidth = e.clientX - (document.querySelector('[data-events-sidebar]') as HTMLElement)?.getBoundingClientRect().left;
      if (newWidth) setSidebarWidth(Math.max(200, Math.min(400, newWidth)));
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
          icon={<ElectricBoltRounded sx={{ fontSize: 28, color: '#E8A84E' }} />}
          title={selectedPath?.tab === 'events' ? 'Select an event or parameter' : 'Select from the tree'}
          description="Add a file, then create domains and events. Click any item to edit its properties."
          accentColor="#E8A84E"
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
        width: sidebarWidth, minWidth: 200, borderRight: 1, borderColor: 'divider', overflow: 'auto', flexShrink: 0,
        '&::-webkit-scrollbar': { width: 5 },
        '&::-webkit-scrollbar-thumb': { bgcolor: 'text.disabled', opacity: 0.5, borderRadius: 3 },
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
          '&:hover .sidebar-line': { opacity: 1, bgcolor: '#DF4926' },
        }}
      >
        <Box className="sidebar-line" sx={{
          width: 3,
          height: 32,
          borderRadius: 2,
          bgcolor: dragging ? '#DF4926' : 'text.disabled',
          opacity: dragging ? 1 : 0.4,
          transition: 'all 0.15s ease',
        }} />
      </Box>
      <Box sx={{ flex: 1, overflow: 'auto', p: 3 }}>
        {renderEditor()}
      </Box>
    </Box>
  );
}
