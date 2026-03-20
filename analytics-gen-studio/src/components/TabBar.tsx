import { useEffect, useMemo } from 'react';
import Tabs from '@mui/material/Tabs';
import Tab from '@mui/material/Tab';
import Box from '@mui/material/Box';
import Badge from '@mui/material/Badge';
import Typography from '@mui/material/Typography';
import Tooltip from '@mui/material/Tooltip';
import SettingsRounded from '@mui/icons-material/SettingsRounded';
import ElectricBoltRounded from '@mui/icons-material/ElectricBoltRounded';
import ShareRounded from '@mui/icons-material/ShareRounded';
import LayersRounded from '@mui/icons-material/LayersRounded';
import { useStore } from '../state/store.ts';
import { useValidation } from '../hooks/useValidation.ts';
import type { TabId } from '../types/index.ts';

const isMac = typeof navigator !== 'undefined' && /Mac/.test(navigator.platform);
const modKey = isMac ? '\u2318' : 'Ctrl+';

const tabs: { id: TabId; label: string; icon: React.ReactElement }[] = [
  { id: 'config', label: 'Config', icon: <SettingsRounded sx={{ fontSize: 18 }} /> },
  { id: 'events', label: 'Events', icon: <ElectricBoltRounded sx={{ fontSize: 18 }} /> },
  { id: 'shared', label: 'Shared Params', icon: <ShareRounded sx={{ fontSize: 18 }} /> },
  { id: 'contexts', label: 'Contexts', icon: <LayersRounded sx={{ fontSize: 18 }} /> },
];

export default function TabBar() {
  const activeTab = useStore((s) => s.activeTab);
  const setActiveTab = useStore((s) => s.setActiveTab);
  const eventFiles = useStore((s) => s.eventFiles);
  const sharedParamFiles = useStore((s) => s.sharedParamFiles);
  const contextFiles = useStore((s) => s.contextFiles);
  const errors = useValidation();

  const itemCounts = useMemo(() => {
    const eventsCount = eventFiles.reduce((sum, f) => sum + Object.values(f.domains).reduce((s, evts) => s + Object.keys(evts).length, 0), 0);
    const sharedCount = sharedParamFiles.reduce((sum, f) => sum + Object.keys(f.parameters).length, 0);
    const contextsCount = contextFiles.reduce((sum, f) => sum + Object.keys(f.properties).length, 0);
    return { config: 0, events: eventsCount, shared: sharedCount, contexts: contextsCount } as Record<TabId, number>;
  }, [eventFiles, sharedParamFiles, contextFiles]);

  const errorCounts = tabs.reduce((acc, t) => {
    acc[t.id] = errors.filter((e) => e.tab === t.id).length;
    return acc;
  }, {} as Record<TabId, number>);

  // Keyboard shortcuts: Ctrl+1-4 to switch tabs
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      const mod = e.metaKey || e.ctrlKey;
      if (!mod) return;
      const num = parseInt(e.key, 10);
      if (num >= 1 && num <= tabs.length) {
        e.preventDefault();
        setActiveTab(tabs[num - 1].id);
      }
    };
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, [setActiveTab]);

  return (
    <Box sx={{ px: 2, bgcolor: '#FCFDF7', borderBottom: '1px solid #EEEBE8' }}>
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
        {tabs.map((t, i) => (
          <Tab
            key={t.id}
            value={t.id}
            label={
              <Tooltip title={`${modKey}${i + 1}`} arrow enterDelay={600} placement="bottom">
                <Badge
                  badgeContent={errorCounts[t.id]}
                  color="error"
                  sx={{
                    '& .MuiBadge-badge': {
                      fontSize: '0.6rem', minWidth: 16, height: 16, p: 0,
                      right: -10, top: -2,
                    },
                  }}
                >
                  <Box component="span" sx={{ display: 'inline-flex', alignItems: 'center', gap: 0.5 }}>
                    {t.label}
                    {itemCounts[t.id] > 0 && (
                      <Typography component="span" sx={{ fontSize: '0.65rem', color: '#bbb', fontWeight: 500 }}>
                        {itemCounts[t.id]}
                      </Typography>
                    )}
                  </Box>
                </Badge>
              </Tooltip>
            }
            icon={t.icon}
            iconPosition="start"
            disableRipple
          />
        ))}
      </Tabs>
    </Box>
  );
}
