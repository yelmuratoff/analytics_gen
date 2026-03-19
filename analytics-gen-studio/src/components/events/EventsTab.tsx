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
        />
      );
    }

    return (
      <EventEditor
        fileIndex={selectedPath.fileIndex}
        domain={selectedPath.domain!}
        eventName={selectedPath.event}
        eventEditorSchema={eventEditorSchema}
      />
    );
  };

  return (
    <Box sx={{ display: 'flex', height: '100%', mx: -3, mt: -1 }}>
      <Box sx={{ width: 260, minWidth: 220, borderRight: '1px solid #EEEBE8', overflow: 'auto' }}>
        <FileTree />
      </Box>
      <Box sx={{ flex: 1, overflow: 'auto', p: 3 }}>
        {renderEditor()}
      </Box>
    </Box>
  );
}
