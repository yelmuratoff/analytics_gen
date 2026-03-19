import Tabs from '@mui/material/Tabs';
import Tab from '@mui/material/Tab';
import Box from '@mui/material/Box';
import SettingsRounded from '@mui/icons-material/SettingsRounded';
import ElectricBoltRounded from '@mui/icons-material/ElectricBoltRounded';
import ShareRounded from '@mui/icons-material/ShareRounded';
import LayersRounded from '@mui/icons-material/LayersRounded';
import { useStore } from '../state/store.ts';
import type { TabId } from '../types/index.ts';

const tabs: { id: TabId; label: string; icon: React.ReactElement }[] = [
  { id: 'config', label: 'Config', icon: <SettingsRounded sx={{ fontSize: 18 }} /> },
  { id: 'events', label: 'Events', icon: <ElectricBoltRounded sx={{ fontSize: 18 }} /> },
  { id: 'shared', label: 'Shared Params', icon: <ShareRounded sx={{ fontSize: 18 }} /> },
  { id: 'contexts', label: 'Contexts', icon: <LayersRounded sx={{ fontSize: 18 }} /> },
];

export default function TabBar() {
  const activeTab = useStore((s) => s.activeTab);
  const setActiveTab = useStore((s) => s.setActiveTab);

  return (
    <Box sx={{ px: 2, bgcolor: '#FFFFFF', borderBottom: '1px solid #EEEBE8' }}>
      <Tabs
        value={activeTab}
        onChange={(_, v) => setActiveTab(v as TabId)}
        sx={{
          minHeight: 44,
          '& .MuiTabs-indicator': { height: 2.5, borderRadius: '2px 2px 0 0', bgcolor: '#DF4926' },
          '& .MuiTab-root': {
            minHeight: 44, py: 0, px: 2, gap: 0.7,
            color: '#999', fontSize: '0.84rem',
            '&.Mui-selected': { color: '#1A1A1A' },
          },
        }}
      >
        {tabs.map((t) => (
          <Tab key={t.id} value={t.id} label={t.label} icon={t.icon} iconPosition="start" disableRipple />
        ))}
      </Tabs>
    </Box>
  );
}
