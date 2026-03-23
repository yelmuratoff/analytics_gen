import { useEffect, useMemo } from 'react';
import Tabs from '@mui/material/Tabs';
import Tab from '@mui/material/Tab';
import Box from '@mui/material/Box';
import Badge from '@mui/material/Badge';
import Typography from '@mui/material/Typography';
import Tooltip from '@mui/material/Tooltip';
import useMediaQuery from '@mui/material/useMediaQuery';
import { useTheme } from '@mui/material/styles';
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

interface TabBarProps {
  children?: React.ReactNode;
}

export default function TabBar({ children }: TabBarProps) {
  const activeTab = useStore((s) => s.activeTab);
  const setActiveTab = useStore((s) => s.setActiveTab);
  const config = useStore((s) => s.config);
  const eventFiles = useStore((s) => s.eventFiles);
  const sharedParamFiles = useStore((s) => s.sharedParamFiles);
  const contextFiles = useStore((s) => s.contextFiles);
  const errors = useValidation();
  const theme = useTheme();
  const isCompact = useMediaQuery(theme.breakpoints.down('md'));

  const itemCounts = useMemo(() => {
    const configCount = Object.values(config as unknown as Record<string, Record<string, unknown>>).reduce((sum, section) => {
      if (typeof section !== 'object' || section === null) return sum;
      return sum + Object.values(section).filter((v) => {
        if (v == null) return false;
        if (typeof v === 'boolean') return v === true;
        if (typeof v === 'string') return v !== '';
        if (Array.isArray(v)) return v.length > 0;
        if (typeof v === 'object') return Object.keys(v as object).length > 0;
        return true;
      }).length;
    }, 0);
    const eventsCount = eventFiles.reduce((sum, f) => sum + Object.values(f.domains).reduce((s, evts) => s + Object.keys(evts).length, 0), 0);
    const sharedCount = sharedParamFiles.reduce((sum, f) => sum + Object.keys(f.parameters).length, 0);
    const contextsCount = contextFiles.reduce((sum, f) => sum + Object.keys(f.properties).length, 0);
    return { config: configCount, events: eventsCount, shared: sharedCount, contexts: contextsCount } as Record<TabId, number>;
  }, [config, eventFiles, sharedParamFiles, contextFiles]);

  const errorCounts = useMemo(() =>
    tabs.reduce((acc, t) => {
      acc[t.id] = errors.filter((e) => e.tab === t.id).length;
      return acc;
    }, {} as Record<TabId, number>),
  [errors]);

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

  const countLabel = (id: TabId, n: number): string => {
    switch (id) {
      case 'config': return `${n} field${n === 1 ? '' : 's'} configured`;
      case 'events': return `${n} event${n === 1 ? '' : 's'}`;
      case 'shared': return `${n} parameter${n === 1 ? '' : 's'}`;
      case 'contexts': return `${n} ${n === 1 ? 'property' : 'properties'}`;
    }
  };

  return (
    <Box sx={{ px: 2, bgcolor: 'background.paper', borderBottom: 1, borderColor: 'divider', display: 'flex', alignItems: 'center' }}>
      <Tabs
        value={activeTab}
        onChange={(_, v) => setActiveTab(v as TabId)}
        variant={isCompact ? 'fullWidth' : 'standard'}
        sx={{
          minHeight: 44,
          overflow: 'visible',
          '& .MuiTabs-scroller': { overflow: 'visible !important' },
          '& .MuiTabs-flexContainer': { overflow: 'visible' },
          '& .MuiTabs-indicator': { height: 2.5, borderRadius: '2px 2px 0 0', bgcolor: 'primary.main' },
          '& .MuiTab-root': {
            minHeight: 44, py: 0, px: isCompact ? 1 : 2, gap: 0.7,
            color: 'text.secondary', fontSize: '0.86rem',
            minWidth: isCompact ? 44 : undefined,
            overflow: 'visible',
            '&.Mui-selected': { color: 'text.primary' },
          },
        }}
      >
        {tabs.map((t, i) => (
          <Tab
            key={t.id}
            value={t.id}
            label={
              <Tooltip title={`${isCompact ? `${t.label} \u2022 ` : ''}${modKey}${i + 1}`} arrow enterDelay={600} placement="bottom">
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
                  <Box component="span" sx={{ display: 'inline-flex', alignItems: 'center', gap: 0.7 }}>
                    {!isCompact && t.label}
                    {!isCompact && itemCounts[t.id] > 0 && (
                      <Tooltip title={countLabel(t.id, itemCounts[t.id])} arrow enterDelay={400} placement="top">
                        <Box component="span" sx={{
                          display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
                          minWidth: 20, height: 18, px: 0.5,
                          borderRadius: 2,
                          bgcolor: activeTab === t.id ? (th: any) => `${th.palette.primary.main}1A` : 'action.hover',
                        }}>
                          <Typography component="span" sx={{
                            fontSize: '0.68rem', fontWeight: 600,
                            color: activeTab === t.id ? 'primary.main' : 'text.disabled',
                          }}>
                            {itemCounts[t.id]}
                          </Typography>
                        </Box>
                      </Tooltip>
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
      {children}
    </Box>
  );
}
