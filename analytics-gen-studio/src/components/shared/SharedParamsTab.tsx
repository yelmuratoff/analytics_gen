import { useState, useMemo, useCallback, useRef } from 'react';
import Box from '@mui/material/Box';
import List from '@mui/material/List';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemText from '@mui/material/ListItemText';
import ListItemIcon from '@mui/material/ListItemIcon';
import IconButton from '@mui/material/IconButton';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import Collapse from '@mui/material/Collapse';
import TextField from '@mui/material/TextField';
import InputAdornment from '@mui/material/InputAdornment';
import Chip from '@mui/material/Chip';
import InsertDriveFileRounded from '@mui/icons-material/InsertDriveFileRounded';
import CircleRounded from '@mui/icons-material/CircleRounded';
import KeyboardArrowRightRounded from '@mui/icons-material/KeyboardArrowRightRounded';
import KeyboardArrowDownRounded from '@mui/icons-material/KeyboardArrowDownRounded';
import DeleteOutlineRounded from '@mui/icons-material/DeleteOutlineRounded';
import AddRounded from '@mui/icons-material/AddRounded';
import ShareRounded from '@mui/icons-material/ShareRounded';
import SearchRounded from '@mui/icons-material/SearchRounded';
import UnfoldMoreRounded from '@mui/icons-material/UnfoldMoreRounded';
import UnfoldLessRounded from '@mui/icons-material/UnfoldLessRounded';
import Tooltip from '@mui/material/Tooltip';
import { alpha } from '@mui/material/styles';
import type { RJSFSchema } from '@rjsf/utils';
import { useStore } from '../../state/store.ts';
import { DEFAULT_PARAM_TYPE } from '../../schemas/constants.ts';
import AddItemDialog from '../AddItemDialog.tsx';
import ConfirmDialog from '../ConfirmDialog.tsx';
import EmptyState from '../EmptyState.tsx';
import SharedParamEditor from './SharedParamEditor.tsx';

interface SharedParamsTabProps {
  parameterSchema: RJSFSchema;
}

export default function SharedParamsTab({ parameterSchema }: SharedParamsTabProps) {
  const files = useStore((s) => s.sharedParamFiles);
  const eventFiles = useStore((s) => s.eventFiles);
  const selectedPath = useStore((s) => s.selectedPath);
  const setSelectedPath = useStore((s) => s.setSelectedPath);
  const addSharedParamFile = useStore((s) => s.addSharedParamFile);
  const removeSharedParamFile = useStore((s) => s.removeSharedParamFile);
  const addSharedParam = useStore((s) => s.addSharedParam);
  const removeSharedParam = useStore((s) => s.removeSharedParam);

  const [search, setSearch] = useState('');
  const [addFileOpen, setAddFileOpen] = useState(false);
  const [addParamOpen, setAddParamOpen] = useState<number | null>(null);
  const [collapsedFiles, setCollapsedFiles] = useState<Set<number>>(new Set());
  const [confirmDelete, setConfirmDelete] = useState<{ title: string; message: string; action: () => void } | null>(null);
  const [sidebarWidth, setSidebarWidth] = useState(240);
  const [dragging, setDragging] = useState(false);
  const isDragging = useRef(false);

  const handleMouseDown = useCallback(() => {
    isDragging.current = true;
    setDragging(true);
    document.body.style.cursor = 'col-resize';
    document.body.style.userSelect = 'none';

    const handleMouseMove = (e: MouseEvent) => {
      if (!isDragging.current) return;
      const sidebar = document.querySelector('[data-shared-sidebar]') as HTMLElement;
      if (sidebar) {
        const newWidth = e.clientX - sidebar.getBoundingClientRect().left;
        setSidebarWidth(Math.max(200, Math.min(400, newWidth)));
      }
    };

    const handleMouseUp = () => {
      isDragging.current = false;
      setDragging(false);
      document.body.style.cursor = '';
      document.body.style.userSelect = '';
      window.removeEventListener('mousemove', handleMouseMove);
      window.removeEventListener('mouseup', handleMouseUp);
    };

    window.addEventListener('mousemove', handleMouseMove);
    window.addEventListener('mouseup', handleMouseUp);
  }, []);

  const usageCounts = useMemo(() => {
    const counts: Record<string, number> = {};
    eventFiles.forEach((ef) => {
      Object.values(ef.domains).forEach((events) => {
        Object.values(events).forEach((event) => {
          Object.entries(event.parameters).forEach(([pn, pv]) => {
            if (pv === null) {
              counts[pn] = (counts[pn] ?? 0) + 1;
            }
          });
        });
      });
    });
    return counts;
  }, [eventFiles]);

  const q = search.toLowerCase();

  const isFileExpanded = (i: number) => !collapsedFiles.has(i);
  const toggleExpand = (i: number) => {
    setCollapsedFiles((prev) => {
      const next = new Set(prev);
      if (next.has(i)) next.delete(i); else next.add(i);
      return next;
    });
  };
  const allExpanded = files.length > 0 && collapsedFiles.size === 0;
  const expandAllFiles = () => setCollapsedFiles(new Set());
  const collapseAllFiles = () => setCollapsedFiles(new Set(files.map((_, i) => i)));

  const isSel = (fi: number, p?: string) =>
    selectedPath?.tab === 'shared' && selectedPath.fileIndex === fi && selectedPath.parameter === p;

  const hoverDel = {
    opacity: 0.2, transition: 'opacity 0.15s', color: 'text.disabled', p: 0.5,
    '&:hover': { color: '#D32F2F', bgcolor: 'rgba(211,47,47,0.06)', opacity: 1 },
    '.MuiListItemButton-root:hover &': { opacity: 1 },
  };

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

  const fileMatchesSearch = (fi: number) => {
    if (!q) return true;
    const file = files[fi];
    if (file.fileName.toLowerCase().includes(q)) return true;
    return Object.keys(file.parameters).some((pn) => pn.toLowerCase().includes(q));
  };

  return (
    <Box sx={{ display: 'flex', height: '100%', mx: -3, mt: -1 }}>
      <Box data-shared-sidebar sx={{
        width: sidebarWidth, minWidth: 200, borderRight: 1, borderColor: 'divider', overflow: 'auto', flexShrink: 0,
        '&::-webkit-scrollbar': { width: 5 },
        '&::-webkit-scrollbar-thumb': { bgcolor: 'text.disabled', opacity: 0.5, borderRadius: 3 },
      }}>
        <Box sx={{ p: 1.5, display: 'flex', flexDirection: 'column', gap: 1 }}>
          <Box sx={{ display: 'flex', gap: 0.5 }}>
            <Button startIcon={<AddRounded />} size="small" onClick={() => setAddFileOpen(true)}
              fullWidth variant="outlined" sx={{ fontSize: '0.82rem', py: 0.5 }}>
              Add File
            </Button>
            {files.length > 0 && (
              <Tooltip title={allExpanded ? 'Collapse all' : 'Expand all'} arrow>
                <IconButton size="small" onClick={allExpanded ? collapseAllFiles : expandAllFiles} sx={{
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
              bgcolor: 'rgba(34,160,107,0.06)', border: '2px dashed', borderColor: '#22A06B',
            }}>
              <ShareRounded sx={{ fontSize: 28, color: '#22A06B' }} />
            </Box>
            <Typography sx={{ fontSize: '0.85rem', color: 'text.secondary', mb: 0.5, fontWeight: 600 }}>No files yet</Typography>
            <Typography sx={{ fontSize: '0.78rem', color: 'text.disabled', lineHeight: 1.5, px: 1, mb: 2 }}>
              Shared parameters can be referenced from any event across files.
            </Typography>
            <Button size="small" variant="contained" onClick={() => setAddFileOpen(true)} sx={{ fontSize: '0.78rem' }}>
              Add your first file
            </Button>
          </Box>
        )}
        <List dense disablePadding sx={{ px: 0.5, pb: 1 }}>
          {files.map((file, fi) => {
            if (!fileMatchesSearch(fi)) return null;
            return (
              <Box key={fi}>
                <ListItemButton onClick={() => toggleExpand(fi)} dense sx={{ py: 0.4 }}>
                  {isFileExpanded(fi) ? <KeyboardArrowDownRounded sx={{ fontSize: 18, color: 'text.secondary' }} />
                    : <KeyboardArrowRightRounded sx={{ fontSize: 18, color: 'text.disabled' }} />}
                  <ListItemIcon sx={{ minWidth: 26, ml: 0.2 }}>
                    <InsertDriveFileRounded sx={{ fontSize: 17, color: '#22A06B' }} />
                  </ListItemIcon>
                  <ListItemText
                    primary={<>{file.fileName}<Typography component="span" sx={{ fontSize: '0.78rem', color: 'text.disabled', ml: 0.5 }}>{Object.keys(file.parameters).length || ''}</Typography></>}
                    primaryTypographyProps={{ fontSize: '0.85rem', fontWeight: 600 }}
                  />
                  <IconButton size="small" onClick={(e) => {
                    e.stopPropagation();
                    setConfirmDelete({ title: `Delete ${file.fileName}?`, message: 'All parameters in this file will be removed.', action: () => removeSharedParamFile(fi) });
                  }} sx={hoverDel}>
                    <DeleteOutlineRounded sx={{ fontSize: 16 }} />
                  </IconButton>
                </ListItemButton>
                <Collapse in={isFileExpanded(fi) || !!q}>
                  <List dense disablePadding>
                    {Object.keys(file.parameters).map((pn) => {
                      if (q && !pn.toLowerCase().includes(q) && !file.fileName.toLowerCase().includes(q)) return null;
                      const uses = usageCounts[pn] ?? 0;
                      return (
                        <ListItemButton key={pn} sx={{
                          pl: 5.5, py: 0.4,
                          ...(isSel(fi, pn) && { bgcolor: alpha('#DF4926', 0.06) }),
                        }} onClick={() => setSelectedPath({ tab: 'shared', fileIndex: fi, parameter: pn })}>
                          <ListItemIcon sx={{ minWidth: 18 }}>
                            <CircleRounded sx={{ fontSize: 6, color: 'text.disabled' }} />
                          </ListItemIcon>
                          <ListItemText
                            primary={
                              <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                                <span>{pn}</span>
                                {uses > 0 && (
                                  <Chip label={`${uses} use${uses > 1 ? 's' : ''}`} size="small" sx={{
                                    height: 16, fontSize: '0.6rem', fontWeight: 600,
                                    bgcolor: 'rgba(46,125,50,0.08)', color: 'success.main',
                                    '& .MuiChip-label': { px: 0.6 },
                                  }} />
                                )}
                              </Box>
                            }
                            primaryTypographyProps={{
                              fontSize: '0.78rem', fontFamily: '"JetBrains Mono", monospace',
                            }}
                          />
                          <IconButton size="small" onClick={(e) => {
                            e.stopPropagation();
                            setConfirmDelete({ title: `Delete "${pn}"?`, message: `This will remove the shared parameter "${pn}".`, action: () => removeSharedParam(fi, pn) });
                          }} sx={hoverDel}>
                            <DeleteOutlineRounded sx={{ fontSize: 15 }} />
                          </IconButton>
                        </ListItemButton>
                      );
                    })}
                    {!q && (
                      <ListItemButton sx={{ pl: 5.5, ...addBtnSx }} onClick={() => setAddParamOpen(fi)}>
                        <AddRounded sx={{ fontSize: 15, color: '#DF4926', mr: 0.5 }} />
                        <ListItemText primary="Add Parameter" primaryTypographyProps={{
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
        {q && files.length > 0 && files.every((_, fi) => !fileMatchesSearch(fi)) && (
          <Typography sx={{ px: 2, py: 3, textAlign: 'center', fontSize: '0.78rem', color: 'text.disabled' }}>
            No matches for "{search}"
          </Typography>
        )}
      </Box>
      {/* Resize handle */}
      <Box
        role="separator"
        aria-label="Resize sidebar"
        onMouseDown={handleMouseDown}
        sx={{
          width: 12, cursor: 'col-resize', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
          '&:hover .shared-line': { opacity: 1, bgcolor: '#DF4926' },
        }}
      >
        <Box className="shared-line" sx={{
          width: 3, height: 32, borderRadius: 2,
          bgcolor: dragging ? '#DF4926' : 'text.disabled',
          opacity: dragging ? 1 : 0.4,
          transition: 'all 0.15s ease',
        }} />
      </Box>
      <Box sx={{ flex: 1, overflow: 'auto', p: 3 }}>
        {selectedPath?.tab === 'shared' && selectedPath.parameter ? (
          <SharedParamEditor fileIndex={selectedPath.fileIndex} paramName={selectedPath.parameter} parameterSchema={parameterSchema} />
        ) : (
          <EmptyState
            icon={<ShareRounded sx={{ fontSize: 28, color: '#22A06B' }} />}
            title="Select a parameter"
            description="Shared parameters can be referenced from any event. Click one to edit."
            accentColor="#22A06B"
          />
        )}
      </Box>
      <AddItemDialog open={addFileOpen} title="Add File" label="File name" placeholder="shared_user.yaml"
        isFileName existingNames={files.map((f) => f.fileName)} onClose={() => setAddFileOpen(false)}
        onAdd={(n) => addSharedParamFile(n.endsWith('.yaml') ? n : `${n}.yaml`)} />
      {addParamOpen !== null && (
        <AddItemDialog open title="Add Parameter" label="Name" placeholder="session_id"
          validateSnakeCase existingNames={Object.keys(files[addParamOpen]?.parameters ?? {})}
          onClose={() => setAddParamOpen(null)}
          onAdd={(n) => {
            addSharedParam(addParamOpen, n, { type: DEFAULT_PARAM_TYPE });
            setSelectedPath({ tab: 'shared', fileIndex: addParamOpen, parameter: n });
            setAddParamOpen(null);
          }} />
      )}
      {confirmDelete && (
        <ConfirmDialog open title={confirmDelete.title} message={confirmDelete.message}
          onConfirm={() => { confirmDelete.action(); setConfirmDelete(null); }}
          onCancel={() => setConfirmDelete(null)} />
      )}
    </Box>
  );
}
