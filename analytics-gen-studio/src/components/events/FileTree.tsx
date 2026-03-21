import { useState, useMemo } from 'react';
import Box from '@mui/material/Box';
import List from '@mui/material/List';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemText from '@mui/material/ListItemText';
import ListItemIcon from '@mui/material/ListItemIcon';
import IconButton from '@mui/material/IconButton';
import Button from '@mui/material/Button';
import Chip from '@mui/material/Chip';
import Collapse from '@mui/material/Collapse';
import Menu from '@mui/material/Menu';
import MenuItem from '@mui/material/MenuItem';
import Typography from '@mui/material/Typography';
import TextField from '@mui/material/TextField';
import InputAdornment from '@mui/material/InputAdornment';
import InsertDriveFileRounded from '@mui/icons-material/InsertDriveFileRounded';
import FolderRounded from '@mui/icons-material/FolderRounded';
import ElectricBoltRounded from '@mui/icons-material/ElectricBoltRounded';
import CircleRounded from '@mui/icons-material/CircleRounded';
import LinkRounded from '@mui/icons-material/LinkRounded';
import KeyboardArrowRightRounded from '@mui/icons-material/KeyboardArrowRightRounded';
import KeyboardArrowDownRounded from '@mui/icons-material/KeyboardArrowDownRounded';
import ContentCopyRounded from '@mui/icons-material/ContentCopyRounded';
import DeleteOutlineRounded from '@mui/icons-material/DeleteOutlineRounded';
import AddRounded from '@mui/icons-material/AddRounded';
import SearchRounded from '@mui/icons-material/SearchRounded';
import UnfoldMoreRounded from '@mui/icons-material/UnfoldMoreRounded';
import UnfoldLessRounded from '@mui/icons-material/UnfoldLessRounded';
import Tooltip from '@mui/material/Tooltip';
import { alpha } from '@mui/material/styles';
import { useStore } from '../../state/store.ts';
import { DEFAULT_PARAM_TYPE } from '../../schemas/constants.ts';
import AddItemDialog from '../AddItemDialog.tsx';
import ConfirmDialog from '../ConfirmDialog.tsx';

interface EditingItem {
  type: 'file' | 'domain' | 'event' | 'param';
  fi: number;
  domain?: string;
  event?: string;
  param?: string;
  original: string;
}

export default function FileTree() {
  const files = useStore((s) => s.eventFiles);
  const sharedParamFiles = useStore((s) => s.sharedParamFiles);
  const selectedPath = useStore((s) => s.selectedPath);
  const setSelectedPath = useStore((s) => s.setSelectedPath);
  const addEventFile = useStore((s) => s.addEventFile);
  const removeEventFile = useStore((s) => s.removeEventFile);
  const addDomain = useStore((s) => s.addDomain);
  const removeDomain = useStore((s) => s.removeDomain);
  const addEvent = useStore((s) => s.addEvent);
  const removeEvent = useStore((s) => s.removeEvent);
  const addParameter = useStore((s) => s.addParameter);
  const removeParameter = useStore((s) => s.removeParameter);
  const duplicateEvent = useStore((s) => s.duplicateEvent);
  const duplicateParameter = useStore((s) => s.duplicateParameter);
  const renameEventFile = useStore((s) => s.renameEventFile);
  const renameDomain = useStore((s) => s.renameDomain);
  const renameEvent = useStore((s) => s.renameEvent);
  const renameParameter = useStore((s) => s.renameParameter);

  const [search, setSearch] = useState('');
  const [editing, setEditing] = useState<EditingItem | null>(null);
  const [editValue, setEditValue] = useState('');

  const allKeys = useMemo(() => {
    const keys = new Set<string>();
    files.forEach((file, fi) => {
      const fk = `f${fi}`;
      keys.add(fk);
      Object.entries(file.domains).forEach(([dn, events]) => {
        const dk = `${fk}.d${dn}`;
        keys.add(dk);
        Object.keys(events).forEach((en) => keys.add(`${dk}.e${en}`));
      });
    });
    return keys;
  }, [files]);

  const [collapsed, setCollapsed] = useState<Set<string>>(new Set());
  const [addFileOpen, setAddFileOpen] = useState(false);
  const [addDomainFor, setAddDomainFor] = useState<number | null>(null);
  const [addEventFor, setAddEventFor] = useState<{ fi: number; domain: string } | null>(null);
  const [addParamFor, setAddParamFor] = useState<{ fi: number; domain: string; event: string } | null>(null);
  const [sharedAnchorEl, setSharedAnchorEl] = useState<HTMLElement | null>(null);
  const [addMenuAnchor, setAddMenuAnchor] = useState<HTMLElement | null>(null);
  const [confirmDelete, setConfirmDelete] = useState<{ title: string; message: string; action: () => void } | null>(null);

  const startEditing = (item: EditingItem) => {
    setEditing(item);
    setEditValue(item.original);
  };

  const commitRename = () => {
    if (!editing) return;
    const val = editValue.trim();
    if (!val || val === editing.original) { setEditing(null); return; }
    switch (editing.type) {
      case 'file':
        renameEventFile(editing.fi, val.endsWith('.yaml') ? val : `${val}.yaml`);
        break;
      case 'domain':
        renameDomain(editing.fi, editing.original, val);
        break;
      case 'event':
        renameEvent(editing.fi, editing.domain!, editing.original, val);
        break;
      case 'param':
        renameParameter(editing.fi, editing.domain!, editing.event!, editing.original, val);
        break;
    }
    setEditing(null);
  };

  const allSharedParams = useMemo(() => sharedParamFiles.flatMap((f) => Object.keys(f.parameters)), [sharedParamFiles]);
  const q = search.toLowerCase();

  const isExpanded = (key: string) => allKeys.has(key) && !collapsed.has(key);
  const toggle = (key: string) => {
    setCollapsed((prev) => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key); else next.add(key);
      return next;
    });
  };
  const allExpanded = allKeys.size > 0 && collapsed.size === 0;
  const expandAll = () => setCollapsed(new Set());
  const collapseAll = () => setCollapsed(new Set(allKeys));

  const isSel = (fi: number, domain?: string, event?: string, param?: string) =>
    selectedPath?.tab === 'events' && selectedPath.fileIndex === fi &&
    selectedPath.domain === domain && selectedPath.event === event && selectedPath.parameter === param;

  const hoverAction = {
    opacity: 0.2, transition: 'opacity 0.15s', color: 'text.disabled',
    p: 0.5, flexShrink: 0,
    '&:hover': { color: '#DF4926', bgcolor: 'rgba(223,73,38,0.06)', opacity: 1 },
    '.MuiListItemButton-root:hover &': { opacity: 1 },
  };

  const hoverDel = {
    opacity: 0.2, transition: 'opacity 0.15s', color: 'text.disabled',
    p: 0.5, flexShrink: 0,
    '&:hover': { color: '#D32F2F', bgcolor: 'rgba(211,47,47,0.06)', opacity: 1 },
    '.MuiListItemButton-root:hover &': { opacity: 1 },
  };

  const arrow = (open: boolean) => open
    ? <KeyboardArrowDownRounded sx={{ fontSize: 18, color: 'text.secondary' }} />
    : <KeyboardArrowRightRounded sx={{ fontSize: 18, color: 'text.disabled' }} />;

  const countBadge = (n: number) => (
    <Box component="span" sx={{
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      minWidth: 18, height: 16, px: 0.4, ml: 0.5, flexShrink: 0,
      borderRadius: 1, bgcolor: 'action.hover',
    }}>
      <Typography component="span" sx={{ fontSize: '0.68rem', color: 'text.disabled', fontWeight: 600 }}>
        {n}
      </Typography>
    </Box>
  );

  // Shared sx for ListItemText to prevent overflow
  const truncatedTextSx = { minWidth: 0, '& .MuiListItemText-primary': { display: 'flex', alignItems: 'center', overflow: 'hidden' } };
  const truncatedNameSx = { overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' } as const;

  const confirmDel = (title: string, message: string, action: () => void) => (e: React.MouseEvent) => {
    e.stopPropagation();
    setConfirmDelete({ title, message, action });
  };

  const matchesSearch = (name: string) => !q || name.toLowerCase().includes(q);
  const fileMatchesSearch = (fi: number) => {
    if (!q) return true;
    const file = files[fi];
    if (file.fileName.toLowerCase().includes(q)) return true;
    return Object.entries(file.domains).some(([dn, events]) =>
      dn.toLowerCase().includes(q) ||
      Object.entries(events).some(([en, ev]) =>
        en.toLowerCase().includes(q) ||
        Object.keys(ev.parameters).some((pn) => pn.toLowerCase().includes(q))
      )
    );
  };
  const domainMatchesSearch = (fi: number, dn: string) => {
    if (!q) return true;
    if (dn.toLowerCase().includes(q)) return true;
    const events = files[fi].domains[dn];
    return Object.entries(events).some(([en, ev]) =>
      en.toLowerCase().includes(q) ||
      Object.keys(ev.parameters).some((pn) => pn.toLowerCase().includes(q))
    );
  };
  const eventMatchesSearch = (fi: number, dn: string, en: string) => {
    if (!q) return true;
    if (en.toLowerCase().includes(q)) return true;
    const event = files[fi].domains[dn]?.[en];
    return event ? Object.keys(event.parameters).some((pn) => pn.toLowerCase().includes(q)) : false;
  };

  const itemEnterSx = {
    '@keyframes itemEnter': {
      from: { opacity: 0, transform: 'translateY(-4px)' },
      to: { opacity: 1, transform: 'translateY(0)' },
    },
    animation: 'itemEnter 0.2s ease-out',
  };

  // "Add" button style — ghost with dashed underline to distinguish from real items
  const addBtnSx = {
    py: 0.3,
    opacity: 0.7,
    borderTop: '1px dashed',
    borderColor: 'divider',
    borderRadius: 0,
    mx: 1,
    mt: 0.5,
    '&:hover': { opacity: 1, bgcolor: 'rgba(223,73,38,0.04)' },
  };

  return (
    <>
      <Box sx={{ p: 1.5, display: 'flex', flexDirection: 'column', gap: 1 }}>
        <Box sx={{ display: 'flex', gap: 0.5 }}>
          <Button startIcon={<AddRounded />} size="small" onClick={() => setAddFileOpen(true)}
            fullWidth variant="outlined" sx={{ fontSize: '0.82rem', py: 0.5 }}>
            Add File
          </Button>
          {files.length > 0 && (
            <Tooltip title={allExpanded ? 'Collapse all' : 'Expand all'} arrow>
              <IconButton size="small" onClick={allExpanded ? collapseAll : expandAll} sx={{
                color: 'text.secondary', flexShrink: 0,
                '&:hover': { color: '#DF4926', bgcolor: 'rgba(223,73,38,0.04)' },
              }}>
                {allExpanded ? <UnfoldLessRounded sx={{ fontSize: 18 }} /> : <UnfoldMoreRounded sx={{ fontSize: 18 }} />}
              </IconButton>
            </Tooltip>
          )}
        </Box>
        <TextField
            size="small"
            placeholder={files.length > 0 ? 'Search...' : 'Add a file to search'}
            disabled={files.length === 0}
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            slotProps={{
              input: {
                startAdornment: (
                  <InputAdornment position="start">
                    <SearchRounded sx={{ fontSize: 16, color: 'text.disabled' }} />
                  </InputAdornment>
                ),
                sx: { fontSize: '0.78rem', py: 0, height: 32 },
              },
            }}
          />
      </Box>

      {files.length === 0 && (
        <Box sx={{ px: 2, py: 4, textAlign: 'center' }}>
          <Box sx={{
            width: 56, height: 56, borderRadius: '50%', mx: 'auto', mb: 1.5,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            bgcolor: 'action.hover', border: '2px dashed', borderColor: 'divider',
          }}>
            <InsertDriveFileRounded sx={{ fontSize: 28, color: 'text.disabled' }} />
          </Box>
          <Typography sx={{ fontSize: '0.85rem', color: 'text.secondary', mb: 0.5, fontWeight: 600 }}>No event files yet</Typography>
          <Typography sx={{ fontSize: '0.78rem', color: 'text.disabled', mb: 2, lineHeight: 1.5, px: 1 }}>
            Create a YAML file, then add domains and events with parameters inside.
          </Typography>
          <Button size="small" variant="contained" onClick={() => setAddFileOpen(true)}
            sx={{ fontSize: '0.78rem' }}>
            Create your first file
          </Button>
        </Box>
      )}

      <List dense disablePadding sx={{ px: 0.5, pb: 1 }}>
        {files.map((file, fi) => {
          if (!fileMatchesSearch(fi)) return null;
          const fk = `f${fi}`;
          const totalEvents = Object.values(file.domains).reduce((sum, evts) => sum + Object.keys(evts).length, 0);
          return (
            <Box key={fi} sx={itemEnterSx}>
              <ListItemButton onClick={() => toggle(fk)} dense sx={{ py: 0.4 }}>
                {arrow(isExpanded(fk))}
                <ListItemIcon sx={{ minWidth: 26, ml: 0.2 }}>
                  <InsertDriveFileRounded sx={{ fontSize: 17, color: '#8B9DAF' }} />
                </ListItemIcon>
                {editing?.type === 'file' && editing.fi === fi ? (
                  <TextField size="small" autoFocus value={editValue}
                    onChange={(e) => setEditValue(e.target.value)}
                    onBlur={commitRename}
                    onKeyDown={(e) => { if (e.key === 'Enter') commitRename(); if (e.key === 'Escape') setEditing(null); }}
                    onClick={(e) => e.stopPropagation()}
                    slotProps={{ input: { sx: { fontSize: '0.82rem', py: 0, height: 26 } } }}
                    sx={{ flex: 1 }}
                  />
                ) : (
                  <ListItemText
                    primary={<><Box component="span" sx={truncatedNameSx}>{file.fileName}</Box>{totalEvents > 0 && countBadge(totalEvents)}</>}
                    primaryTypographyProps={{ fontSize: '0.85rem', fontWeight: 600 }}
                    sx={truncatedTextSx}
                    onDoubleClick={(e) => { e.stopPropagation(); startEditing({ type: 'file', fi, original: file.fileName }); }}
                  />
                )}
                <IconButton size="small" onClick={confirmDel(
                  `Delete ${file.fileName}?`,
                  `This will remove all domains, events and parameters in this file.`,
                  () => removeEventFile(fi),
                )} sx={hoverDel}>
                  <DeleteOutlineRounded sx={{ fontSize: 16 }} />
                </IconButton>
              </ListItemButton>
              <Collapse in={isExpanded(fk) || !!q} unmountOnExit>
                <List dense disablePadding sx={{ position: 'relative', '&::before': { content: '""', position: 'absolute', left: 24, top: 0, bottom: 0, width: '1px', bgcolor: 'divider' } }}>
                  {Object.entries(file.domains).map(([dn, events]) => {
                    if (!domainMatchesSearch(fi, dn)) return null;
                    const dk = `${fk}.d${dn}`;
                    const eventCount = Object.keys(events).length;
                    return (
                      <Box key={dn} sx={itemEnterSx}>
                        <ListItemButton sx={{
                          pl: 4, py: 0.35,
                          ...(isSel(fi, dn, undefined, undefined) && !selectedPath?.event && { bgcolor: alpha('#DF4926', 0.06) }),
                        }} onClick={() => {
                          toggle(dk);
                          setSelectedPath({ tab: 'events', fileIndex: fi, domain: dn });
                        }} dense>
                          {arrow(isExpanded(dk))}
                          <ListItemIcon sx={{ minWidth: 24, ml: 0.2 }}>
                            <FolderRounded sx={{ fontSize: 16, color: '#DF4926' }} />
                          </ListItemIcon>
                          {editing?.type === 'domain' && editing.fi === fi && editing.original === dn ? (
                            <TextField size="small" autoFocus value={editValue}
                              onChange={(e) => setEditValue(e.target.value)}
                              onBlur={commitRename}
                              onKeyDown={(e) => { if (e.key === 'Enter') commitRename(); if (e.key === 'Escape') setEditing(null); }}
                              onClick={(e) => e.stopPropagation()}
                              slotProps={{ input: { sx: { fontSize: '0.78rem', py: 0, height: 24 } } }}
                              sx={{ flex: 1 }}
                            />
                          ) : (
                            <ListItemText
                              primary={<><Box component="span" sx={truncatedNameSx}>{dn}</Box>{eventCount > 0 && countBadge(eventCount)}</>}
                              primaryTypographyProps={{ fontSize: '0.82rem', fontWeight: 600, color: '#DF4926' }}
                              sx={truncatedTextSx}
                              onDoubleClick={(e) => { e.stopPropagation(); startEditing({ type: 'domain', fi, original: dn }); }}
                            />
                          )}
                          <IconButton size="small" onClick={confirmDel(
                            `Delete domain "${dn}"?`,
                            `This will remove ${eventCount} event(s) and all their parameters.`,
                            () => removeDomain(fi, dn),
                          )} sx={hoverDel}>
                            <DeleteOutlineRounded sx={{ fontSize: 15 }} />
                          </IconButton>
                        </ListItemButton>
                        <Collapse in={isExpanded(dk) || !!q} unmountOnExit>
                          <List dense disablePadding sx={{ position: 'relative', '&::before': { content: '""', position: 'absolute', left: 44, top: 0, bottom: 0, width: '1px', bgcolor: 'divider' } }}>
                            {Object.entries(events).map(([en, event]) => {
                              if (!eventMatchesSearch(fi, dn, en)) return null;
                              const ek = `${dk}.e${en}`;
                              const paramCount = Object.keys(event.parameters).length;
                              return (
                                <Box key={en} sx={itemEnterSx}>
                                  <ListItemButton sx={{
                                    pl: 6.5, py: 0.4,
                                    ...(isSel(fi, dn, en, undefined) && { bgcolor: alpha('#DF4926', 0.06) }),
                                  }} onClick={() => {
                                    toggle(ek);
                                    setSelectedPath({ tab: 'events', fileIndex: fi, domain: dn, event: en });
                                  }} dense>
                                    {arrow(isExpanded(ek))}
                                    <ListItemIcon sx={{ minWidth: 22, ml: 0.2 }}>
                                      <ElectricBoltRounded sx={{ fontSize: 15, color: '#E8A84E' }} />
                                    </ListItemIcon>
                                    {editing?.type === 'event' && editing.fi === fi && editing.domain === dn && editing.original === en ? (
                                      <TextField size="small" autoFocus value={editValue}
                                        onChange={(e) => setEditValue(e.target.value)}
                                        onBlur={commitRename}
                                        onKeyDown={(e) => { if (e.key === 'Enter') commitRename(); if (e.key === 'Escape') setEditing(null); }}
                                        onClick={(e) => e.stopPropagation()}
                                        slotProps={{ input: { sx: { fontSize: '0.78rem', py: 0, height: 24 } } }}
                                        sx={{ flex: 1 }}
                                      />
                                    ) : (
                                      <ListItemText
                                        primary={<><Box component="span" sx={truncatedNameSx}>{en}</Box>{paramCount > 0 && countBadge(paramCount)}</>}
                                        primaryTypographyProps={{ fontSize: '0.82rem', fontWeight: 500 }}
                                        sx={truncatedTextSx}
                                        onDoubleClick={(e) => { e.stopPropagation(); startEditing({ type: 'event', fi, domain: dn, original: en }); }}
                                      />
                                    )}
                                    <Tooltip title="Duplicate" arrow enterDelay={400}>
                                      <IconButton size="small" onClick={(e) => { e.stopPropagation(); duplicateEvent(fi, dn, en); }} sx={hoverAction}>
                                        <ContentCopyRounded sx={{ fontSize: 14 }} />
                                      </IconButton>
                                    </Tooltip>
                                    <IconButton size="small" onClick={confirmDel(
                                      `Delete event "${en}"?`,
                                      `This will remove the event and its ${paramCount} parameter(s).`,
                                      () => removeEvent(fi, dn, en),
                                    )} sx={hoverDel}>
                                      <DeleteOutlineRounded sx={{ fontSize: 15 }} />
                                    </IconButton>
                                  </ListItemButton>
                                  <Collapse in={isExpanded(ek) || !!q} unmountOnExit>
                                    <List dense disablePadding sx={{ position: 'relative', '&::before': { content: '""', position: 'absolute', left: 68, top: 0, bottom: 0, width: '1px', bgcolor: 'divider' } }}>
                                      {Object.entries(event.parameters).map(([pn, pv]) => {
                                        if (!matchesSearch(pn)) return null;
                                        return (
                                          <ListItemButton key={pn} sx={{
                                            pl: 9.5, py: 0.4,
                                            ...(isSel(fi, dn, en, pn) && { bgcolor: alpha('#DF4926', 0.06) }),
                                          }} onClick={() => setSelectedPath({
                                            tab: 'events', fileIndex: fi, domain: dn, event: en, parameter: pn,
                                          })} dense>
                                            <ListItemIcon sx={{ minWidth: 18 }}>
                                              {pv === null
                                                ? <LinkRounded sx={{ fontSize: 14, color: '#6366F1' }} />
                                                : <CircleRounded sx={{ fontSize: 6, color: 'text.disabled' }} />}
                                            </ListItemIcon>
                                            {editing?.type === 'param' && editing.fi === fi && editing.domain === dn && editing.event === en && editing.original === pn ? (
                                              <TextField size="small" autoFocus value={editValue}
                                                onChange={(e) => setEditValue(e.target.value)}
                                                onBlur={commitRename}
                                                onKeyDown={(e) => { if (e.key === 'Enter') commitRename(); if (e.key === 'Escape') setEditing(null); }}
                                                onClick={(e) => e.stopPropagation()}
                                                slotProps={{ input: { sx: { fontSize: '0.75rem', py: 0, height: 22, fontFamily: '"JetBrains Mono", monospace' } } }}
                                                sx={{ flex: 1 }}
                                              />
                                            ) : (
                                              <ListItemText
                                                sx={truncatedTextSx}
                                                primary={
                                                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                                                    <Box component="span" sx={truncatedNameSx}>{pn}</Box>
                                                    {pv === null && (
                                                      <Chip label="shared" size="small" sx={{
                                                        height: 16, fontSize: '0.6rem', fontWeight: 600,
                                                        bgcolor: 'rgba(99,102,241,0.08)', color: '#6366F1',
                                                        '& .MuiChip-label': { px: 0.6 },
                                                      }} />
                                                    )}
                                                  </Box>
                                                }
                                                secondary={pv !== null ? (typeof pv === 'string' ? pv : pv?.type) : undefined}
                                                primaryTypographyProps={{ fontSize: '0.78rem', fontFamily: '"JetBrains Mono", monospace' }}
                                                secondaryTypographyProps={{ fontSize: '0.78rem' }}
                                                onDoubleClick={(e) => { e.stopPropagation(); startEditing({ type: 'param', fi, domain: dn, event: en, param: pn, original: pn }); }}
                                              />
                                            )}
                                            <Tooltip title="Duplicate" arrow enterDelay={400}>
                                              <IconButton size="small" onClick={(e) => { e.stopPropagation(); duplicateParameter(fi, dn, en, pn); }} sx={hoverAction}>
                                                <ContentCopyRounded sx={{ fontSize: 13 }} />
                                              </IconButton>
                                            </Tooltip>
                                            <IconButton size="small" onClick={confirmDel(
                                              `Delete parameter "${pn}"?`,
                                              `This will remove the parameter from event "${en}".`,
                                              () => removeParameter(fi, dn, en, pn),
                                            )} sx={hoverDel}>
                                              <DeleteOutlineRounded sx={{ fontSize: 14 }} />
                                            </IconButton>
                                          </ListItemButton>
                                        );
                                      })}
                                      {!q && (
                                        <ListItemButton sx={{ pl: 9.5, ...addBtnSx }} onClick={(e) => {
                                          setAddParamFor({ fi, domain: dn, event: en });
                                          if (allSharedParams.length > 0) {
                                            setAddMenuAnchor(e.currentTarget);
                                          }
                                        }} dense>
                                          <AddRounded sx={{ fontSize: 14, color: '#DF4926', mr: 0.5 }} />
                                          <ListItemText primary="Add" primaryTypographyProps={{
                                            fontSize: '0.78rem', color: '#DF4926', fontWeight: 600,
                                          }} />
                                        </ListItemButton>
                                      )}
                                    </List>
                                  </Collapse>
                                </Box>
                              );
                            })}
                            {!q && (
                              <ListItemButton sx={{ pl: 6.5, ...addBtnSx }}
                                onClick={() => setAddEventFor({ fi, domain: dn })} dense>
                                <AddRounded sx={{ fontSize: 15, color: '#DF4926', mr: 0.5 }} />
                                <ListItemText primary="Add Event" primaryTypographyProps={{
                                  fontSize: '0.78rem', color: '#DF4926', fontWeight: 600,
                                }} />
                              </ListItemButton>
                            )}
                          </List>
                        </Collapse>
                      </Box>
                    );
                  })}
                  {!q && (
                    <ListItemButton sx={{ pl: 4, ...addBtnSx }} onClick={() => setAddDomainFor(fi)} dense>
                      <AddRounded sx={{ fontSize: 16, color: '#DF4926', mr: 0.5 }} />
                      <ListItemText primary="Add Domain" primaryTypographyProps={{
                        fontSize: '0.78rem', color: '#DF4926', fontWeight: 600,
                      }} />
                    </ListItemButton>
                  )}
                </List>
              </Collapse>
            </Box>
          );
        })}
      </List>

      {/* No search results */}
      {q && files.length > 0 && files.every((_, fi) => !fileMatchesSearch(fi)) && (
        <Typography sx={{ px: 2, py: 3, textAlign: 'center', fontSize: '0.78rem', color: 'text.disabled' }}>
          No matches for "{search}"
        </Typography>
      )}

      {/* Add parameter menu (local + shared options) */}
      <Menu anchorEl={addMenuAnchor} open={!!addMenuAnchor}
        onClose={() => { setAddMenuAnchor(null); setAddParamFor(null); }}
        slotProps={{ paper: { sx: { borderRadius: 3, minWidth: 180 } } }}>
        <MenuItem onClick={() => {
          setAddMenuAnchor(null);
        }} sx={{ fontSize: '0.85rem' }}>
          <AddRounded sx={{ fontSize: 15, mr: 1, color: '#DF4926' }} />
          New local parameter
        </MenuItem>
        {allSharedParams.length > 0 && (
          <MenuItem onClick={() => {
            const anchor = addMenuAnchor;
            setAddMenuAnchor(null);
            requestAnimationFrame(() => setSharedAnchorEl(anchor));
          }} sx={{ fontSize: '0.85rem' }}>
            <LinkRounded sx={{ fontSize: 15, mr: 1, color: '#6366F1' }} />
            Link shared parameter
          </MenuItem>
        )}
      </Menu>
      {/* Shared param picker */}
      <Menu anchorEl={sharedAnchorEl} open={!!sharedAnchorEl}
        onClose={() => { setSharedAnchorEl(null); setAddParamFor(null); }}
        slotProps={{ paper: { sx: { borderRadius: 3, minWidth: 180 } } }}>
        {allSharedParams.map((sp) => (
          <MenuItem key={sp} onClick={() => {
            if (addParamFor) addParameter(addParamFor.fi, addParamFor.domain, addParamFor.event, sp, null);
            setSharedAnchorEl(null); setAddParamFor(null);
          }} sx={{ fontSize: '0.85rem', fontFamily: '"JetBrains Mono", monospace' }}>
            <LinkRounded sx={{ fontSize: 15, mr: 1, color: '#6366F1' }} />
            {sp}
          </MenuItem>
        ))}
      </Menu>

      {/* Confirm delete */}
      {confirmDelete && (
        <ConfirmDialog
          open
          title={confirmDelete.title}
          message={confirmDelete.message}
          onConfirm={() => { confirmDelete.action(); setConfirmDelete(null); }}
          onCancel={() => setConfirmDelete(null)}
        />
      )}

      {/* Add dialogs */}
      <AddItemDialog open={addFileOpen} title="Add Event File" label="File name" placeholder="auth.yaml"
        isFileName existingNames={files.map((f) => f.fileName)} onClose={() => setAddFileOpen(false)}
        onAdd={(n) => { addEventFile(n.endsWith('.yaml') ? n : `${n}.yaml`); setAddFileOpen(false); setAddDomainFor(files.length); }} />
      {addDomainFor !== null && !addEventFor && (
        <AddItemDialog open title="Add Domain" label="Domain name" placeholder="auth"
          validateSnakeCase existingNames={Object.keys(files[addDomainFor]?.domains ?? {})} onClose={() => setAddDomainFor(null)}
          onAdd={(n) => { addDomain(addDomainFor, n); setAddDomainFor(null); }} />
      )}
      {addEventFor && !sharedAnchorEl && (
        <AddItemDialog open title="Add Event" label="Event name" placeholder="login"
          validateSnakeCase existingNames={Object.keys(files[addEventFor.fi]?.domains[addEventFor.domain] ?? {})}
          onClose={() => setAddEventFor(null)}
          onAdd={(n) => {
            addEvent(addEventFor.fi, addEventFor.domain, n);
            setSelectedPath({ tab: 'events', fileIndex: addEventFor.fi, domain: addEventFor.domain, event: n });
            setAddEventFor(null);
          }} />
      )}
      {addParamFor && !sharedAnchorEl && !addMenuAnchor && (
        <AddItemDialog open title="Add Parameter" label="Parameter name" placeholder="session_id"
          validateSnakeCase existingNames={Object.keys(files[addParamFor.fi]?.domains[addParamFor.domain]?.[addParamFor.event]?.parameters ?? {})}
          onClose={() => setAddParamFor(null)}
          onAdd={(n) => {
            addParameter(addParamFor.fi, addParamFor.domain, addParamFor.event, n, { type: DEFAULT_PARAM_TYPE });
            setSelectedPath({ tab: 'events', fileIndex: addParamFor.fi, domain: addParamFor.domain, event: addParamFor.event, parameter: n });
            setAddParamFor(null);
          }} />
      )}
    </>
  );
}
