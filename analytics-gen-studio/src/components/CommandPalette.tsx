import { useState, useMemo, useEffect, useRef } from 'react';
import Dialog from '@mui/material/Dialog';
import Box from '@mui/material/Box';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';
import InputAdornment from '@mui/material/InputAdornment';
import Divider from '@mui/material/Divider';
import SearchRounded from '@mui/icons-material/SearchRounded';
import SettingsRounded from '@mui/icons-material/SettingsRounded';
import ElectricBoltRounded from '@mui/icons-material/ElectricBoltRounded';
import FolderRounded from '@mui/icons-material/FolderRounded';
import CircleRounded from '@mui/icons-material/CircleRounded';
import ShareRounded from '@mui/icons-material/ShareRounded';
import LayersRounded from '@mui/icons-material/LayersRounded';
import FolderZipRounded from '@mui/icons-material/FolderZipRounded';
import UndoRounded from '@mui/icons-material/UndoRounded';
import RedoRounded from '@mui/icons-material/RedoRounded';
import SaveRounded from '@mui/icons-material/SaveRounded';
import FileOpenRounded from '@mui/icons-material/FileOpenRounded';
import DarkModeRounded from '@mui/icons-material/DarkModeRounded';
import LightModeRounded from '@mui/icons-material/LightModeRounded';
import { useStore } from '../state/store.ts';
import type { SelectionPath, TabId } from '../types/index.ts';

const isMac = typeof navigator !== 'undefined' && /Mac/.test(navigator.platform);
const mod = isMac ? '\u2318' : 'Ctrl+';

interface PaletteItem {
  label: string;
  secondary: string;
  icon: React.ReactNode;
  kind: 'action' | 'navigation';
  shortcut?: string;
  tab?: TabId;
  path?: SelectionPath | null;
  action?: () => void;
}

export interface CommandPaletteActions {
  onSave?: () => void;
  onOpen?: () => void;
  onExportZip?: () => void;
  onUndo?: () => void;
  onRedo?: () => void;
  onToggleTheme?: () => void;
  isDarkMode?: boolean;
}

interface CommandPaletteProps {
  open: boolean;
  onClose: () => void;
  actions?: CommandPaletteActions;
}

export default function CommandPalette({ open, onClose, actions }: CommandPaletteProps) {
  const [query, setQuery] = useState('');
  const [selectedIndex, setSelectedIndex] = useState(0);
  const listRef = useRef<HTMLDivElement>(null);

  const config = useStore((s) => s.config);
  const eventFiles = useStore((s) => s.eventFiles);
  const sharedParamFiles = useStore((s) => s.sharedParamFiles);
  const contextFiles = useStore((s) => s.contextFiles);
  const setActiveTab = useStore((s) => s.setActiveTab);
  const setSelectedPath = useStore((s) => s.setSelectedPath);

  const actionItems = useMemo((): PaletteItem[] => {
    const items: PaletteItem[] = [];
    if (actions?.onSave) items.push({ label: 'Save Project', secondary: 'Action', shortcut: `${mod}S`, icon: <SaveRounded sx={{ fontSize: 16, color: 'text.secondary' }} />, kind: 'action', action: actions.onSave });
    if (actions?.onOpen) items.push({ label: 'Open Project', secondary: 'Action', shortcut: `${mod}O`, icon: <FileOpenRounded sx={{ fontSize: 16, color: 'text.secondary' }} />, kind: 'action', action: actions.onOpen });
    if (actions?.onExportZip) items.push({ label: 'Export ZIP', secondary: 'Action', shortcut: `${mod}\u21E7E`, icon: <FolderZipRounded sx={{ fontSize: 16, color: '#DF4926' }} />, kind: 'action', action: actions.onExportZip });
    if (actions?.onUndo) items.push({ label: 'Undo', secondary: 'Action', shortcut: `${mod}Z`, icon: <UndoRounded sx={{ fontSize: 16, color: 'text.secondary' }} />, kind: 'action', action: actions.onUndo });
    if (actions?.onRedo) items.push({ label: 'Redo', secondary: 'Action', shortcut: `${mod}\u21E7Z`, icon: <RedoRounded sx={{ fontSize: 16, color: 'text.secondary' }} />, kind: 'action', action: actions.onRedo });
    if (actions?.onToggleTheme) items.push({
      label: actions.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
      secondary: 'Action',
      icon: actions.isDarkMode ? <LightModeRounded sx={{ fontSize: 16, color: '#E8A84E' }} /> : <DarkModeRounded sx={{ fontSize: 16, color: '#6366F1' }} />,
      kind: 'action', action: actions.onToggleTheme,
    });
    // Tab navigation
    items.push({ label: 'Config', secondary: 'Go to tab', shortcut: `${mod}1`, icon: <SettingsRounded sx={{ fontSize: 16, color: '#DF4926' }} />, kind: 'action', action: () => setActiveTab('config') });
    items.push({ label: 'Events', secondary: 'Go to tab', shortcut: `${mod}2`, icon: <ElectricBoltRounded sx={{ fontSize: 16, color: '#E8A84E' }} />, kind: 'action', action: () => setActiveTab('events') });
    items.push({ label: 'Shared Params', secondary: 'Go to tab', shortcut: `${mod}3`, icon: <ShareRounded sx={{ fontSize: 16, color: '#22A06B' }} />, kind: 'action', action: () => setActiveTab('shared') });
    items.push({ label: 'Contexts', secondary: 'Go to tab', shortcut: `${mod}4`, icon: <LayersRounded sx={{ fontSize: 16, color: '#6366F1' }} />, kind: 'action', action: () => setActiveTab('contexts') });
    return items;
  }, [actions, setActiveTab]);

  const navItems = useMemo((): PaletteItem[] => {
    const items: PaletteItem[] = [];

    // Config sections
    const configSections = Object.keys(config as unknown as Record<string, unknown>);
    configSections.forEach((section) => {
      items.push({
        label: section, secondary: 'Config',
        icon: <SettingsRounded sx={{ fontSize: 16, color: '#DF4926' }} />,
        kind: 'navigation', tab: 'config', path: null,
      });
    });

    // Events
    eventFiles.forEach((file, fi) => {
      items.push({
        label: file.fileName, secondary: 'Event file',
        icon: <ElectricBoltRounded sx={{ fontSize: 16, color: '#E8A84E' }} />,
        kind: 'navigation', tab: 'events', path: { tab: 'events', fileIndex: fi },
      });
      Object.entries(file.domains).forEach(([dn, events]) => {
        items.push({
          label: dn, secondary: `Domain \u2022 ${file.fileName}`,
          icon: <FolderRounded sx={{ fontSize: 16, color: '#DF4926' }} />,
          kind: 'navigation', tab: 'events', path: { tab: 'events', fileIndex: fi, domain: dn },
        });
        Object.entries(events).forEach(([en, event]) => {
          items.push({
            label: en, secondary: `Event \u2022 ${dn}`,
            icon: <ElectricBoltRounded sx={{ fontSize: 16, color: '#E8A84E' }} />,
            kind: 'navigation', tab: 'events', path: { tab: 'events', fileIndex: fi, domain: dn, event: en },
          });
          Object.keys(event.parameters).forEach((pn) => {
            items.push({
              label: pn, secondary: `Param \u2022 ${dn}/${en}`,
              icon: <CircleRounded sx={{ fontSize: 8, color: 'text.disabled' }} />,
              kind: 'navigation', tab: 'events', path: { tab: 'events', fileIndex: fi, domain: dn, event: en, parameter: pn },
            });
          });
        });
      });
    });

    // Shared params
    sharedParamFiles.forEach((file, fi) => {
      Object.keys(file.parameters).forEach((pn) => {
        items.push({
          label: pn, secondary: `Shared \u2022 ${file.fileName}`,
          icon: <ShareRounded sx={{ fontSize: 16, color: '#22A06B' }} />,
          kind: 'navigation', tab: 'shared', path: { tab: 'shared', fileIndex: fi, parameter: pn },
        });
      });
    });

    // Contexts
    contextFiles.forEach((file, fi) => {
      Object.keys(file.properties).forEach((pn) => {
        items.push({
          label: pn, secondary: `Context \u2022 ${file.contextName}`,
          icon: <LayersRounded sx={{ fontSize: 16, color: '#6366F1' }} />,
          kind: 'navigation', tab: 'contexts', path: { tab: 'contexts', fileIndex: fi, contextProperty: pn },
        });
      });
    });

    return items;
  }, [config, eventFiles, sharedParamFiles, contextFiles]);

  const filtered = useMemo(() => {
    const q = query.toLowerCase().trim();
    if (!q) {
      // Show actions first, then first 30 nav items
      return [...actionItems, ...navItems.slice(0, 30)];
    }
    // Fuzzy match: check if all characters of query appear in order in the target
    const fuzzyMatch = (text: string, pattern: string): boolean => {
      let pi = 0;
      for (let i = 0; i < text.length && pi < pattern.length; i++) {
        if (text[i] === pattern[pi]) pi++;
      }
      return pi === pattern.length;
    };
    // Score: exact includes > starts with > fuzzy
    const score = (text: string): number => {
      const lower = text.toLowerCase();
      if (lower.includes(q)) return 3;
      if (fuzzyMatch(lower, q)) return 1;
      return 0;
    };
    const matchAndSort = (items: PaletteItem[]) =>
      items
        .map((item) => ({ item, s: Math.max(score(item.label), score(item.secondary)) }))
        .filter(({ s }) => s > 0)
        .sort((a, b) => b.s - a.s)
        .map(({ item }) => item);
    const matchedActions = matchAndSort(actionItems);
    const matchedNav = matchAndSort(navItems).slice(0, 40);
    return [...matchedActions, ...matchedNav];
  }, [actionItems, navItems, query]);

  const actionCount = useMemo(() => filtered.filter((i) => i.kind === 'action').length, [filtered]);

  useEffect(() => {
    setSelectedIndex(0);
  }, [query]);

  useEffect(() => {
    if (!open) {
      setQuery('');
      setSelectedIndex(0);
    }
  }, [open]);

  // Scroll selected item into view
  useEffect(() => {
    if (!listRef.current) return;
    const el = listRef.current.querySelector(`[data-index="${selectedIndex}"]`) as HTMLElement;
    el?.scrollIntoView({ block: 'nearest' });
  }, [selectedIndex]);

  const handleSelect = (item: PaletteItem) => {
    if (item.action) {
      item.action();
    } else if (item.tab) {
      setActiveTab(item.tab);
      if (item.path) setSelectedPath(item.path);
    }
    onClose();
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      setSelectedIndex((i) => Math.min(i + 1, filtered.length - 1));
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      setSelectedIndex((i) => Math.max(i - 1, 0));
    } else if (e.key === 'Enter') {
      e.preventDefault();
      if (filtered[selectedIndex]) handleSelect(filtered[selectedIndex]);
    }
  };

  let renderedIndex = 0;

  return (
    <Dialog
      open={open}
      onClose={onClose}
      maxWidth="sm"
      fullWidth
      slotProps={{
        paper: {
          sx: {
            borderRadius: 3,
            overflow: 'hidden',
            mt: '15vh',
            alignSelf: 'flex-start',
          },
        },
      }}
    >
      <TextField
        autoFocus
        fullWidth
        placeholder="Search actions, events, parameters..."
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        onKeyDown={handleKeyDown}
        slotProps={{
          input: {
            startAdornment: (
              <InputAdornment position="start">
                <SearchRounded sx={{ fontSize: 20, color: 'text.disabled' }} />
              </InputAdornment>
            ),
            sx: {
              fontSize: '0.95rem', py: 1.5, px: 2,
              borderRadius: 0,
              '& fieldset': { border: 'none' },
            },
          },
        }}
      />
      <Box aria-live="polite" aria-atomic="true" sx={{ position: 'absolute', width: 1, height: 1, overflow: 'hidden', clip: 'rect(0,0,0,0)' }}>
        {filtered.length} result{filtered.length !== 1 ? 's' : ''}
      </Box>
      <Box sx={{ borderTop: 1, borderColor: 'divider', maxHeight: 360, overflow: 'auto' }} ref={listRef}>
        {filtered.length === 0 && (
          <Typography sx={{ p: 3, textAlign: 'center', fontSize: '0.85rem', color: 'text.disabled' }}>
            No results for &quot;{query}&quot;
          </Typography>
        )}
        {filtered.map((item, i) => {
          const idx = renderedIndex++;
          const showSectionDivider = i === actionCount && actionCount > 0 && filtered.length > actionCount;
          return (
            <Box key={`${item.kind}-${item.label}-${i}`}>
              {showSectionDivider && (
                <Divider sx={{ my: 0.5 }}>
                  <Typography sx={{ fontSize: '0.65rem', color: 'text.disabled', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                    Navigate
                  </Typography>
                </Divider>
              )}
              <Box
                data-index={idx}
                onClick={() => handleSelect(item)}
                sx={{
                  display: 'flex', alignItems: 'center', gap: 1.5,
                  px: 2.5, py: 0.8,
                  cursor: 'pointer',
                  bgcolor: i === selectedIndex ? 'action.selected' : 'transparent',
                  '&:hover': { bgcolor: 'action.hover' },
                }}
              >
                <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', width: 24 }}>
                  {item.icon}
                </Box>
                <Box sx={{ flex: 1, minWidth: 0 }}>
                  <Typography sx={{
                    fontSize: '0.85rem', fontWeight: 500,
                    fontFamily: item.kind === 'navigation' ? '"JetBrains Mono", monospace' : '"DM Sans", sans-serif',
                    overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
                  }}>
                    {item.label}
                  </Typography>
                </Box>
                {item.shortcut && (
                  <Box component="kbd" sx={{
                    px: 0.7, py: 0.15, borderRadius: 0.5,
                    border: 1, borderColor: 'divider', bgcolor: 'action.hover',
                    fontSize: '0.65rem', fontWeight: 600, fontFamily: '"JetBrains Mono", monospace',
                    color: 'text.disabled', whiteSpace: 'nowrap', flexShrink: 0,
                  }}>
                    {item.shortcut}
                  </Box>
                )}
                <Typography sx={{ fontSize: '0.72rem', color: 'text.disabled', whiteSpace: 'nowrap', flexShrink: 0 }}>
                  {item.secondary}
                </Typography>
              </Box>
            </Box>
          );
        })}
      </Box>
      <Box sx={{
        borderTop: 1, borderColor: 'divider',
        px: 2, py: 0.8,
        display: 'flex', gap: 2,
      }}>
        <Typography sx={{ fontSize: '0.7rem', color: 'text.disabled' }}>
          <Box component="kbd" sx={{ px: 0.5, py: 0.15, borderRadius: 0.5, border: 1, borderColor: 'divider', fontSize: '0.65rem', mr: 0.3 }}>&uarr;&darr;</Box>
          navigate
        </Typography>
        <Typography sx={{ fontSize: '0.7rem', color: 'text.disabled' }}>
          <Box component="kbd" sx={{ px: 0.5, py: 0.15, borderRadius: 0.5, border: 1, borderColor: 'divider', fontSize: '0.65rem', mr: 0.3 }}>Enter</Box>
          select
        </Typography>
        <Typography sx={{ fontSize: '0.7rem', color: 'text.disabled' }}>
          <Box component="kbd" sx={{ px: 0.5, py: 0.15, borderRadius: 0.5, border: 1, borderColor: 'divider', fontSize: '0.65rem', mr: 0.3 }}>Esc</Box>
          close
        </Typography>
      </Box>
    </Dialog>
  );
}
