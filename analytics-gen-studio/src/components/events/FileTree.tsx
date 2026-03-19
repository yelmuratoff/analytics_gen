import { useState, useMemo } from 'react';
import Box from '@mui/material/Box';
import List from '@mui/material/List';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemText from '@mui/material/ListItemText';
import ListItemIcon from '@mui/material/ListItemIcon';
import IconButton from '@mui/material/IconButton';
import Button from '@mui/material/Button';
import Collapse from '@mui/material/Collapse';
import Menu from '@mui/material/Menu';
import MenuItem from '@mui/material/MenuItem';
import Typography from '@mui/material/Typography';
import InsertDriveFileRounded from '@mui/icons-material/InsertDriveFileRounded';
import FolderRounded from '@mui/icons-material/FolderRounded';
import ElectricBoltRounded from '@mui/icons-material/ElectricBoltRounded';
import CircleRounded from '@mui/icons-material/CircleRounded';
import LinkRounded from '@mui/icons-material/LinkRounded';
import KeyboardArrowRightRounded from '@mui/icons-material/KeyboardArrowRightRounded';
import KeyboardArrowDownRounded from '@mui/icons-material/KeyboardArrowDownRounded';
import CloseRounded from '@mui/icons-material/CloseRounded';
import AddRounded from '@mui/icons-material/AddRounded';
import { alpha } from '@mui/material/styles';
import { useStore } from '../../state/store.ts';
import AddItemDialog from '../AddItemDialog.tsx';

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

  // Build all possible keys so everything is expanded by default
  const allKeys = useMemo(() => {
    const keys = new Set<string>();
    files.forEach((file, fi) => {
      const fk = `f${fi}`;
      keys.add(fk);
      Object.entries(file.domains).forEach(([dn, events]) => {
        const dk = `${fk}.d${dn}`;
        keys.add(dk);
        Object.keys(events).forEach((en) => {
          keys.add(`${dk}.e${en}`);
        });
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

  const allSharedParams = sharedParamFiles.flatMap((f) => Object.keys(f.parameters));

  const isExpanded = (key: string) => allKeys.has(key) && !collapsed.has(key);

  const toggle = (key: string) => {
    setCollapsed((prev) => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key); else next.add(key);
      return next;
    });
  };

  const isSel = (fi: number, domain?: string, event?: string, param?: string) =>
    selectedPath?.tab === 'events' && selectedPath.fileIndex === fi &&
    selectedPath.domain === domain && selectedPath.event === event && selectedPath.parameter === param;

  const hoverDel = {
    opacity: 0, transition: 'opacity 0.15s', color: '#ccc',
    '&:hover': { color: '#D32F2F' },
    '.MuiListItemButton-root:hover &': { opacity: 1 },
  };

  const arrow = (open: boolean) => open
    ? <KeyboardArrowDownRounded sx={{ fontSize: 18, color: '#999' }} />
    : <KeyboardArrowRightRounded sx={{ fontSize: 18, color: '#ccc' }} />;

  return (
    <>
      <Box sx={{ p: 1.5 }}>
        <Button startIcon={<AddRounded />} size="small" onClick={() => setAddFileOpen(true)}
          fullWidth variant="outlined" sx={{ fontSize: '0.78rem', py: 0.5 }}>
          Add File
        </Button>
      </Box>

      {files.length === 0 && (
        <Box sx={{ px: 2, py: 4, textAlign: 'center' }}>
          <InsertDriveFileRounded sx={{ fontSize: 30, color: '#E8E4E0', mb: 0.5 }} />
          <Typography sx={{ fontSize: '0.75rem', color: '#ccc' }}>No event files yet</Typography>
        </Box>
      )}

      <List dense disablePadding sx={{ px: 0.5, pb: 1 }}>
        {files.map((file, fi) => {
          const fk = `f${fi}`;
          return (
            <Box key={fi}>
              <ListItemButton onClick={() => toggle(fk)} dense sx={{ py: 0.4 }}>
                {arrow(isExpanded(fk))}
                <ListItemIcon sx={{ minWidth: 26, ml: 0.2 }}>
                  <InsertDriveFileRounded sx={{ fontSize: 17, color: '#E8A84E' }} />
                </ListItemIcon>
                <ListItemText primary={file.fileName} primaryTypographyProps={{
                  fontSize: '0.82rem', fontWeight: 600,
                }} />
                <IconButton size="small" onClick={(e) => { e.stopPropagation(); removeEventFile(fi); }} sx={hoverDel}>
                  <CloseRounded sx={{ fontSize: 14 }} />
                </IconButton>
              </ListItemButton>
              <Collapse in={isExpanded(fk)}>
                <List dense disablePadding>
                  {Object.entries(file.domains).map(([dn, events]) => {
                    const dk = `${fk}.d${dn}`;
                    return (
                      <Box key={dn}>
                        <ListItemButton sx={{ pl: 4, py: 0.35 }} onClick={() => toggle(dk)} dense>
                          {arrow(isExpanded(dk))}
                          <ListItemIcon sx={{ minWidth: 24, ml: 0.2 }}>
                            <FolderRounded sx={{ fontSize: 16, color: '#DF4926' }} />
                          </ListItemIcon>
                          <ListItemText primary={dn} primaryTypographyProps={{
                            fontSize: '0.8rem', fontWeight: 600, color: '#DF4926',
                          }} />
                          <IconButton size="small" onClick={(e) => { e.stopPropagation(); removeDomain(fi, dn); }} sx={hoverDel}>
                            <CloseRounded sx={{ fontSize: 13 }} />
                          </IconButton>
                        </ListItemButton>
                        <Collapse in={isExpanded(dk)}>
                          <List dense disablePadding>
                            {Object.entries(events).map(([en, event]) => {
                              const ek = `${dk}.e${en}`;
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
                                    <ListItemText primary={en} primaryTypographyProps={{
                                      fontSize: '0.78rem', fontWeight: 500,
                                    }} />
                                    <IconButton size="small" onClick={(e) => { e.stopPropagation(); removeEvent(fi, dn, en); }} sx={hoverDel}>
                                      <CloseRounded sx={{ fontSize: 12 }} />
                                    </IconButton>
                                  </ListItemButton>
                                  <Collapse in={isExpanded(ek)}>
                                    <List dense disablePadding>
                                      {Object.entries(event.parameters).map(([pn, pv]) => (
                                        <ListItemButton key={pn} sx={{
                                          pl: 9.5, py: 0.25,
                                          ...(isSel(fi, dn, en, pn) && { bgcolor: alpha('#DF4926', 0.06) }),
                                        }} onClick={() => setSelectedPath({
                                          tab: 'events', fileIndex: fi, domain: dn, event: en, parameter: pn,
                                        })} dense>
                                          <ListItemIcon sx={{ minWidth: 18 }}>
                                            {pv === null
                                              ? <LinkRounded sx={{ fontSize: 14, color: '#DF4926' }} />
                                              : <CircleRounded sx={{ fontSize: 6, color: '#ccc' }} />}
                                          </ListItemIcon>
                                          <ListItemText
                                            primary={pn}
                                            secondary={pv === null ? 'shared' : typeof pv === 'string' ? pv : pv?.type}
                                            primaryTypographyProps={{
                                              fontSize: '0.74rem', fontFamily: '"JetBrains Mono", monospace',
                                            }}
                                            secondaryTypographyProps={{ fontSize: '0.62rem' }}
                                          />
                                          <IconButton size="small" onClick={(e) => {
                                            e.stopPropagation(); removeParameter(fi, dn, en, pn);
                                          }} sx={hoverDel}>
                                            <CloseRounded sx={{ fontSize: 11 }} />
                                          </IconButton>
                                        </ListItemButton>
                                      ))}
                                      <ListItemButton sx={{ pl: 9.5, py: 0.15 }}
                                        onClick={() => setAddParamFor({ fi, domain: dn, event: en })} dense>
                                        <AddRounded sx={{ fontSize: 14, color: '#DF4926', mr: 0.5 }} />
                                        <ListItemText primary="New" primaryTypographyProps={{
                                          fontSize: '0.7rem', color: '#DF4926', fontWeight: 600,
                                        }} />
                                      </ListItemButton>
                                      {allSharedParams.length > 0 && (
                                        <ListItemButton sx={{ pl: 9.5, py: 0.15 }} onClick={(e) => {
                                          setAddParamFor({ fi, domain: dn, event: en });
                                          setSharedAnchorEl(e.currentTarget);
                                        }} dense>
                                          <LinkRounded sx={{ fontSize: 14, color: '#999', mr: 0.5 }} />
                                          <ListItemText primary="Shared" primaryTypographyProps={{
                                            fontSize: '0.7rem', color: '#999', fontWeight: 500,
                                          }} />
                                        </ListItemButton>
                                      )}
                                    </List>
                                  </Collapse>
                                </Box>
                              );
                            })}
                            <ListItemButton sx={{ pl: 6.5, py: 0.2 }}
                              onClick={() => setAddEventFor({ fi, domain: dn })} dense>
                              <AddRounded sx={{ fontSize: 15, color: '#DF4926', mr: 0.5 }} />
                              <ListItemText primary="Add Event" primaryTypographyProps={{
                                fontSize: '0.74rem', color: '#DF4926', fontWeight: 600,
                              }} />
                            </ListItemButton>
                          </List>
                        </Collapse>
                      </Box>
                    );
                  })}
                  <ListItemButton sx={{ pl: 4, py: 0.2 }} onClick={() => setAddDomainFor(fi)} dense>
                    <AddRounded sx={{ fontSize: 16, color: '#DF4926', mr: 0.5 }} />
                    <ListItemText primary="Add Domain" primaryTypographyProps={{
                      fontSize: '0.76rem', color: '#DF4926', fontWeight: 600,
                    }} />
                  </ListItemButton>
                </List>
              </Collapse>
            </Box>
          );
        })}
      </List>

      <Menu anchorEl={sharedAnchorEl} open={!!sharedAnchorEl}
        onClose={() => { setSharedAnchorEl(null); setAddParamFor(null); }}
        slotProps={{ paper: { sx: { borderRadius: 3, minWidth: 180 } } }}>
        {allSharedParams.map((sp) => (
          <MenuItem key={sp} onClick={() => {
            if (addParamFor) addParameter(addParamFor.fi, addParamFor.domain, addParamFor.event, sp, null);
            setSharedAnchorEl(null); setAddParamFor(null);
          }} sx={{ fontSize: '0.82rem', fontFamily: '"JetBrains Mono", monospace' }}>
            <LinkRounded sx={{ fontSize: 15, mr: 1, color: '#DF4926' }} />
            {sp}
          </MenuItem>
        ))}
      </Menu>

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
      {addParamFor && !sharedAnchorEl && (
        <AddItemDialog open title="Add Parameter" label="Parameter name" placeholder="session_id"
          validateSnakeCase existingNames={Object.keys(files[addParamFor.fi]?.domains[addParamFor.domain]?.[addParamFor.event]?.parameters ?? {})}
          onClose={() => setAddParamFor(null)}
          onAdd={(n) => {
            addParameter(addParamFor.fi, addParamFor.domain, addParamFor.event, n, { type: 'string' });
            setSelectedPath({ tab: 'events', fileIndex: addParamFor.fi, domain: addParamFor.domain, event: addParamFor.event, parameter: n });
            setAddParamFor(null);
          }} />
      )}
    </>
  );
}
