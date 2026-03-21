import { useState, useMemo, useEffect, useRef } from 'react';
import Dialog from '@mui/material/Dialog';
import Box from '@mui/material/Box';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';
import InputAdornment from '@mui/material/InputAdornment';
import SearchRounded from '@mui/icons-material/SearchRounded';
import SettingsRounded from '@mui/icons-material/SettingsRounded';
import ElectricBoltRounded from '@mui/icons-material/ElectricBoltRounded';
import FolderRounded from '@mui/icons-material/FolderRounded';
import CircleRounded from '@mui/icons-material/CircleRounded';
import ShareRounded from '@mui/icons-material/ShareRounded';
import LayersRounded from '@mui/icons-material/LayersRounded';
import { useStore } from '../state/store.ts';
import type { SelectionPath, TabId } from '../types/index.ts';

interface PaletteItem {
  label: string;
  secondary: string;
  icon: React.ReactNode;
  tab: TabId;
  path: SelectionPath | null;
}

interface CommandPaletteProps {
  open: boolean;
  onClose: () => void;
}

export default function CommandPalette({ open, onClose }: CommandPaletteProps) {
  const [query, setQuery] = useState('');
  const [selectedIndex, setSelectedIndex] = useState(0);
  const listRef = useRef<HTMLDivElement>(null);

  const config = useStore((s) => s.config);
  const eventFiles = useStore((s) => s.eventFiles);
  const sharedParamFiles = useStore((s) => s.sharedParamFiles);
  const contextFiles = useStore((s) => s.contextFiles);
  const setActiveTab = useStore((s) => s.setActiveTab);
  const setSelectedPath = useStore((s) => s.setSelectedPath);

  const allItems = useMemo((): PaletteItem[] => {
    const items: PaletteItem[] = [];

    // Config sections
    const configSections = Object.keys(config as unknown as Record<string, unknown>);
    configSections.forEach((section) => {
      items.push({
        label: section,
        secondary: 'Config',
        icon: <SettingsRounded sx={{ fontSize: 16, color: '#DF4926' }} />,
        tab: 'config',
        path: null,
      });
    });

    // Events
    eventFiles.forEach((file, fi) => {
      items.push({
        label: file.fileName,
        secondary: 'Event file',
        icon: <ElectricBoltRounded sx={{ fontSize: 16, color: '#E8A84E' }} />,
        tab: 'events',
        path: { tab: 'events', fileIndex: fi },
      });
      Object.entries(file.domains).forEach(([dn, events]) => {
        items.push({
          label: dn,
          secondary: `Domain \u2022 ${file.fileName}`,
          icon: <FolderRounded sx={{ fontSize: 16, color: '#DF4926' }} />,
          tab: 'events',
          path: { tab: 'events', fileIndex: fi, domain: dn },
        });
        Object.entries(events).forEach(([en, event]) => {
          items.push({
            label: en,
            secondary: `Event \u2022 ${dn}`,
            icon: <ElectricBoltRounded sx={{ fontSize: 16, color: '#E8A84E' }} />,
            tab: 'events',
            path: { tab: 'events', fileIndex: fi, domain: dn, event: en },
          });
          Object.keys(event.parameters).forEach((pn) => {
            items.push({
              label: pn,
              secondary: `Param \u2022 ${dn}/${en}`,
              icon: <CircleRounded sx={{ fontSize: 8, color: 'text.disabled' }} />,
              tab: 'events',
              path: { tab: 'events', fileIndex: fi, domain: dn, event: en, parameter: pn },
            });
          });
        });
      });
    });

    // Shared params
    sharedParamFiles.forEach((file, fi) => {
      Object.keys(file.parameters).forEach((pn) => {
        items.push({
          label: pn,
          secondary: `Shared \u2022 ${file.fileName}`,
          icon: <ShareRounded sx={{ fontSize: 16, color: '#22A06B' }} />,
          tab: 'shared',
          path: { tab: 'shared', fileIndex: fi, parameter: pn },
        });
      });
    });

    // Contexts
    contextFiles.forEach((file, fi) => {
      Object.keys(file.properties).forEach((pn) => {
        items.push({
          label: pn,
          secondary: `Context \u2022 ${file.contextName}`,
          icon: <LayersRounded sx={{ fontSize: 16, color: '#6366F1' }} />,
          tab: 'contexts',
          path: { tab: 'contexts', fileIndex: fi, contextProperty: pn },
        });
      });
    });

    return items;
  }, [config, eventFiles, sharedParamFiles, contextFiles]);

  const filtered = useMemo(() => {
    if (!query.trim()) return allItems.slice(0, 50);
    const q = query.toLowerCase();
    return allItems.filter((item) =>
      item.label.toLowerCase().includes(q) ||
      item.secondary.toLowerCase().includes(q)
    ).slice(0, 50);
  }, [allItems, query]);

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
    const el = listRef.current.children[selectedIndex] as HTMLElement;
    el?.scrollIntoView({ block: 'nearest' });
  }, [selectedIndex]);

  const handleSelect = (item: PaletteItem) => {
    setActiveTab(item.tab);
    if (item.path) setSelectedPath(item.path);
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
        placeholder="Search events, parameters, config..."
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
      <Box sx={{ borderTop: 1, borderColor: 'divider', maxHeight: 360, overflow: 'auto' }} ref={listRef}>
        {filtered.length === 0 && (
          <Typography sx={{ p: 3, textAlign: 'center', fontSize: '0.85rem', color: 'text.disabled' }}>
            No results for &quot;{query}&quot;
          </Typography>
        )}
        {filtered.map((item, i) => (
          <Box
            key={`${item.tab}-${item.label}-${i}`}
            onClick={() => handleSelect(item)}
            sx={{
              display: 'flex', alignItems: 'center', gap: 1.5,
              px: 2.5, py: 1,
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
                fontFamily: '"JetBrains Mono", monospace',
                overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
              }}>
                {item.label}
              </Typography>
            </Box>
            <Typography sx={{ fontSize: '0.72rem', color: 'text.disabled', whiteSpace: 'nowrap', flexShrink: 0 }}>
              {item.secondary}
            </Typography>
          </Box>
        ))}
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
