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

  const [search, setSearch] = useState('');

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

  const allSharedParams = sharedParamFiles.flatMap((f) => Object.keys(f.parameters));
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

  const hoverDel = {
    opacity: 0, transition: 'opacity 0.15s', color: '#BCBCBC',
    p: 0.5,
    '&:hover': { color: '#D32F2F', bgcolor: 'rgba(211,47,47,0.06)' },
    '.MuiListItemButton-root:hover &': { opacity: 1 },
  };

  const arrow = (open: boolean) => open
    ? <KeyboardArrowDownRounded sx={{ fontSize: 18, color: '#999' }} />
    : <KeyboardArrowRightRounded sx={{ fontSize: 18, color: '#ccc' }} />;

  const countBadge = (n: number) => (
    <Typography component="span" sx={{ fontSize: '0.75rem', color: '#bbb', ml: 0.5, fontWeight: 500 }}>
      {n}
    </Typography>
  );

  const confirmDel = (title: string, message: string, action: () => void) => (e: React.MouseEvent) => {
    e.stopPropagation();
    setConfirmDelete({ title, message, action });
  };

  // Check if an item matches the search (cascade: if a child matches, parents match)
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

  return (
    <>
      <Box sx={{ p: 1.5, display: 'flex', flexDirection: 'column', gap: 1 }}>
        <Box sx={{ display: 'flex', gap: 0.5 }}>
          <Button startIcon={<AddRounded />} size="small" onClick={() => setAddFileOpen(true)}
            fullWidth variant="outlined" sx={{ fontSize: '0.78rem', py: 0.5 }}>
            Add File
          </Button>
          {files.length > 0 && (
            <Tooltip title={allExpanded ? 'Collapse all' : 'Expand all'} arrow>
              <IconButton size="small" onClick={allExpanded ? collapseAll : expandAll} sx={{
                color: '#999', flexShrink: 0,
                '&:hover': { color: '#DF4926', bgcolor: 'rgba(223,73,38,0.04)' },
              }}>
                {allExpanded ? <UnfoldLessRounded sx={{ fontSize: 18 }} /> : <UnfoldMoreRounded sx={{ fontSize: 18 }} />}
              </IconButton>
            </Tooltip>
          )}
        </Box>
        <TextField
            size="small"
            placeholder={files.length > 0 ? 'Search...' : 'No items yet'}
            disabled={files.length === 0}
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            slotProps={{
              input: {
                startAdornment: (
                  <InputAdornment position="start">
                    <SearchRounded sx={{ fontSize: 16, color: '#bbb' }} />
                  </InputAdornment>
                ),
                sx: { fontSize: '0.76rem', py: 0, height: 32 },
              },
            }}
          />
      </Box>

      {files.length === 0 && (
        <Box sx={{ px: 2, py: 4, textAlign: 'center' }}>
          <InsertDriveFileRounded sx={{ fontSize: 30, color: '#E8E4E0', mb: 1 }} />
          <Typography sx={{ fontSize: '0.78rem', color: '#aaa', mb: 0.5 }}>No event files yet</Typography>
          <Typography sx={{ fontSize: '0.75rem', color: '#ccc', mb: 1.5, lineHeight: 1.5, px: 1 }}>
            Create a YAML file, then add domains and events with parameters inside.
          </Typography>
          <Button size="small" variant="outlined" onClick={() => setAddFileOpen(true)}
            sx={{ fontSize: '0.75rem' }}>
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
            <Box key={fi}>
              <ListItemButton onClick={() => toggle(fk)} dense sx={{ py: 0.4 }}>
                {arrow(isExpanded(fk))}
                <ListItemIcon sx={{ minWidth: 26, ml: 0.2 }}>
                  <InsertDriveFileRounded sx={{ fontSize: 17, color: '#E8A84E' }} />
                </ListItemIcon>
                <ListItemText
                  primary={<>{file.fileName}{totalEvents > 0 && countBadge(totalEvents)}</>}
                  primaryTypographyProps={{ fontSize: '0.82rem', fontWeight: 600 }}
                />
                <IconButton size="small" onClick={confirmDel(
                  `Delete ${file.fileName}?`,
                  `This will remove all domains, events and parameters in this file.`,
                  () => removeEventFile(fi),
                )} sx={hoverDel}>
                  <DeleteOutlineRounded sx={{ fontSize: 16 }} />
                </IconButton>
              </ListItemButton>
              <Collapse in={isExpanded(fk) || !!q}>
                <List dense disablePadding>
                  {Object.entries(file.domains).map(([dn, events]) => {
                    if (!domainMatchesSearch(fi, dn)) return null;
                    const dk = `${fk}.d${dn}`;
                    const eventCount = Object.keys(events).length;
                    return (
                      <Box key={dn}>
                        <ListItemButton sx={{ pl: 4, py: 0.35 }} onClick={() => toggle(dk)} dense>
                          {arrow(isExpanded(dk))}
                          <ListItemIcon sx={{ minWidth: 24, ml: 0.2 }}>
                            <FolderRounded sx={{ fontSize: 16, color: '#DF4926' }} />
                          </ListItemIcon>
                          <ListItemText
                            primary={<>{dn}{eventCount > 0 && countBadge(eventCount)}</>}
                            primaryTypographyProps={{ fontSize: '0.8rem', fontWeight: 600, color: '#DF4926' }}
                          />
                          <IconButton size="small" onClick={confirmDel(
                            `Delete domain "${dn}"?`,
                            `This will remove ${eventCount} event(s) and all their parameters.`,
                            () => removeDomain(fi, dn),
                          )} sx={hoverDel}>
                            <DeleteOutlineRounded sx={{ fontSize: 15 }} />
                          </IconButton>
                        </ListItemButton>
                        <Collapse in={isExpanded(dk) || !!q}>
                          <List dense disablePadding>
                            {Object.entries(events).map(([en, event]) => {
                              if (!eventMatchesSearch(fi, dn, en)) return null;
                              const ek = `${dk}.e${en}`;
                              const paramCount = Object.keys(event.parameters).length;
                              return (
                                <Box key={en}>
                                  <ListItemButton sx={{
                                    pl: 6.5, py: 0.3,
                                    ...(isSel(fi, dn, en, undefined) && { bgcolor: alpha('#DF4926', 0.06) }),
                                  }} onClick={() => {
                                    toggle(ek);
                                    setSelectedPath({ tab: 'events', fileIndex: fi, domain: dn, event: en });
                                  }} dense>
                                    {arrow(isExpanded(ek))}
                                    <ListItemIcon sx={{ minWidth: 22, ml: 0.2 }}>
                                      <ElectricBoltRounded sx={{ fontSize: 15, color: '#E8A84E' }} />
                                    </ListItemIcon>
                                    <ListItemText
                                      primary={<>{en}{paramCount > 0 && countBadge(paramCount)}</>}
                                      primaryTypographyProps={{ fontSize: '0.78rem', fontWeight: 500 }}
                                    />
                                    <IconButton size="small" onClick={confirmDel(
                                      `Delete event "${en}"?`,
                                      `This will remove the event and its ${paramCount} parameter(s).`,
                                      () => removeEvent(fi, dn, en),
                                    )} sx={hoverDel}>
                                      <DeleteOutlineRounded sx={{ fontSize: 15 }} />
                                    </IconButton>
                                  </ListItemButton>
                                  <Collapse in={isExpanded(ek) || !!q}>
                                    <List dense disablePadding>
                                      {Object.entries(event.parameters).map(([pn, pv]) => {
                                        if (!matchesSearch(pn)) return null;
                                        return (
                                          <ListItemButton key={pn} sx={{
                                            pl: 9.5, py: 0.25,
                                            ...(isSel(fi, dn, en, pn) && { bgcolor: alpha('#DF4926', 0.06) }),
                                          }} onClick={() => setSelectedPath({
                                            tab: 'events', fileIndex: fi, domain: dn, event: en, parameter: pn,
                                          })} dense>
                                            <ListItemIcon sx={{ minWidth: 18 }}>
                                              {pv === null
                                                ? <LinkRounded sx={{ fontSize: 14, color: '#6366F1' }} />
                                                : <CircleRounded sx={{ fontSize: 6, color: '#ccc' }} />}
                                            </ListItemIcon>
                                            <ListItemText
                                              primary={
                                                <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                                                  <span>{pn}</span>
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
                                              primaryTypographyProps={{ fontSize: '0.75rem', fontFamily: '"JetBrains Mono", monospace' }}
                                              secondaryTypographyProps={{ fontSize: '0.75rem' }}
                                            />
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
                                        <ListItemButton sx={{ pl: 9.5, py: 0.15 }} onClick={(e) => {
                                          setAddParamFor({ fi, domain: dn, event: en });
                                          if (allSharedParams.length > 0) {
                                            setAddMenuAnchor(e.currentTarget);
                                          } else {
                                            // No shared params — go straight to add local
                                            setAddParamFor({ fi, domain: dn, event: en });
                                          }
                                        }} dense>
                                          <AddRounded sx={{ fontSize: 14, color: '#DF4926', mr: 0.5 }} />
                                          <ListItemText primary="Add" primaryTypographyProps={{
                                            fontSize: '0.75rem', color: '#DF4926', fontWeight: 600,
                                          }} />
                                        </ListItemButton>
                                      )}
                                    </List>
                                  </Collapse>
                                </Box>
                              );
                            })}
                            {!q && (
                              <ListItemButton sx={{ pl: 6.5, py: 0.2 }}
                                onClick={() => setAddEventFor({ fi, domain: dn })} dense>
                                <AddRounded sx={{ fontSize: 15, color: '#DF4926', mr: 0.5 }} />
                                <ListItemText primary="Add Event" primaryTypographyProps={{
                                  fontSize: '0.75rem', color: '#DF4926', fontWeight: 600,
                                }} />
                              </ListItemButton>
                            )}
                          </List>
                        </Collapse>
                      </Box>
                    );
                  })}
                  {!q && (
                    <ListItemButton sx={{ pl: 4, py: 0.2 }} onClick={() => setAddDomainFor(fi)} dense>
                      <AddRounded sx={{ fontSize: 16, color: '#DF4926', mr: 0.5 }} />
                      <ListItemText primary="Add Domain" primaryTypographyProps={{
                        fontSize: '0.76rem', color: '#DF4926', fontWeight: 600,
                      }} />
                    </ListItemButton>
                  )}
                </List>
              </Collapse>
            </Box>
          );
        })}
      </List>

      {/* Add parameter menu (local + shared options) */}
      <Menu anchorEl={addMenuAnchor} open={!!addMenuAnchor}
        onClose={() => { setAddMenuAnchor(null); setAddParamFor(null); }}
        slotProps={{ paper: { sx: { borderRadius: 3, minWidth: 180 } } }}>
        <MenuItem onClick={() => {
          setAddMenuAnchor(null);
          // addParamFor stays set — AddItemDialog will open
        }} sx={{ fontSize: '0.82rem' }}>
          <AddRounded sx={{ fontSize: 15, mr: 1, color: '#DF4926' }} />
          New local parameter
        </MenuItem>
        {allSharedParams.length > 0 && (
          <MenuItem onClick={() => {
            const anchor = addMenuAnchor;
            setAddMenuAnchor(null);
            // Use the original "Add" button as anchor for the shared picker
            requestAnimationFrame(() => setSharedAnchorEl(anchor));
          }} sx={{ fontSize: '0.82rem' }}>
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
          }} sx={{ fontSize: '0.82rem', fontFamily: '"JetBrains Mono", monospace' }}>
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
        onAdd={(n) => { addEventFile(n.endsWith('.yaml') ? n : `${n}.yaml`); setAddFileOpen(false); }} />
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
