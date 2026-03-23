import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Chip from '@mui/material/Chip';
import type { RJSFSchema } from '@rjsf/utils';
import ElectricBoltRounded from '@mui/icons-material/ElectricBoltRounded';
import FolderRounded from '@mui/icons-material/FolderRounded';
import { useStore } from '../../state/store.ts';
import { sidebarScroll } from '../../styles/tree-shared.ts';
import { useResizeHandle } from '../../hooks/useResizeHandle.ts';
import EmptyState from '../EmptyState.tsx';
import ResizeHandle from '../ResizeHandle.tsx';
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
  const setSelectedPath = useStore((s) => s.setSelectedPath);
  const files = useStore((s) => s.eventFiles);
  const { width: sidebarWidth, dragging, atLimit, containerRef: sidebarRef, handleMouseDown } = useResizeHandle({
    initialWidth: 260, storageKey: 'studio-sidebar-events',
  });

  const breadcrumb = (() => {
    if (!selectedPath || selectedPath.tab !== 'events' || !selectedPath.event) return null;
    const file = files[selectedPath.fileIndex];
    if (!file) return null;
    const parts = [file.fileName, selectedPath.domain, selectedPath.event];
    if (selectedPath.parameter) parts.push(selectedPath.parameter);
    return parts.filter(Boolean) as string[];
  })();

  const renderEditor = () => {
    // Domain selected (no event)
    if (selectedPath?.tab === 'events' && selectedPath.domain && !selectedPath.event) {
      const file = files[selectedPath.fileIndex];
      const events = file?.domains[selectedPath.domain];
      const eventNames = events ? Object.keys(events) : [];
      return (
        <Box>
          <Box sx={{ mb: 3 }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <FolderRounded sx={{ fontSize: 20, color: '#DF4926' }} />
              <Typography sx={{ fontSize: '1.05rem', fontWeight: 700, fontFamily: '"JetBrains Mono", monospace', color: '#DF4926' }}>
                {selectedPath.domain}
              </Typography>
            </Box>
            <Typography sx={{ fontSize: '0.78rem', color: 'text.secondary', mt: 0.5 }}>
              {file?.fileName}
            </Typography>
          </Box>
          <Box sx={{ p: 2, borderRadius: 2, border: 1, borderColor: 'divider', bgcolor: 'action.hover' }}>
            <Typography sx={{ fontSize: '0.82rem', fontWeight: 600, color: 'text.secondary', mb: 1.5 }}>
              Events ({eventNames.length})
            </Typography>
            {eventNames.length === 0 ? (
              <Typography sx={{ fontSize: '0.78rem', color: 'text.disabled', fontStyle: 'italic' }}>
                No events yet. Use the sidebar to add events to this domain.
              </Typography>
            ) : (
              <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.8 }}>
                {eventNames.map((en) => (
                  <Chip key={en} label={en} size="small"
                    onClick={() => setSelectedPath({ tab: 'events', fileIndex: selectedPath.fileIndex, domain: selectedPath.domain, event: en })}
                    sx={{
                      fontFamily: '"JetBrains Mono", monospace', fontSize: '0.78rem',
                      cursor: 'pointer', fontWeight: 500,
                      bgcolor: 'transparent', border: '1px solid', borderColor: 'divider',
                      '&:hover': { borderColor: '#DF4926', color: '#DF4926' },
                    }}
                  />
                ))}
              </Box>
            )}
          </Box>
        </Box>
      );
    }

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
      <Box ref={sidebarRef} sx={{
        width: sidebarWidth, minWidth: 200, borderRight: 1, borderColor: 'divider', overflow: 'auto', flexShrink: 0,
        ...sidebarScroll,
      }}>
        <FileTree />
      </Box>
      <ResizeHandle dragging={dragging} atLimit={atLimit} onMouseDown={handleMouseDown} />
      <Box sx={{ flex: 1, overflow: 'auto', p: 3 }}>
        {renderEditor()}
      </Box>
    </Box>
  );
}
