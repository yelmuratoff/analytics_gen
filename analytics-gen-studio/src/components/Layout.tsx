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

  const renderTab = () => {
    switch (activeTab) {
      case 'config':
        return <ConfigTab />;
      case 'events':
        return <EventsTab parameterSchema={schemas.parameterSchema} />;
      case 'shared':
        return <SharedParamsTab parameterSchema={schemas.parameterSchema} />;
      case 'contexts':
        return <ContextsTab parameterSchema={schemas.parameterSchema} />;
    }
  };

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', height: '100vh', bgcolor: 'background.default' }}>
      <Toolbar />
      <TabBar />
      <Box sx={{ display: 'flex', flex: 1, overflow: 'hidden', p: 2, gap: 2 }}>
        {/* Form panel */}
        <Box sx={{
          flex: '0 0 57%', overflow: 'auto', p: 3,
          bgcolor: '#FCFDF7',
          borderRadius: 3,
          border: '1px solid #EEEBE8',
        }}>
          {renderTab()}
        </Box>
        {/* YAML preview panel */}
        <Box sx={{
          flex: 1, overflow: 'hidden',
          bgcolor: '#1E1E1E',
          borderRadius: 3,
          display: 'flex', flexDirection: 'column',
        }}>
          <YamlPreview />
        </Box>
      </Box>
    </Box>
  );
}
