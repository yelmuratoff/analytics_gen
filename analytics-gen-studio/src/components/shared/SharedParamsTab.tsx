import { useState, useMemo, useTransition } from 'react';
import Box from '@mui/material/Box';
import List from '@mui/material/List';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemText from '@mui/material/ListItemText';
import ListItemIcon from '@mui/material/ListItemIcon';
import IconButton from '@mui/material/IconButton';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import CircularProgress from '@mui/material/CircularProgress';
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
import { hoverDelete, addItemButton, sidebarScroll } from '../../styles/tree-shared.ts';
import { useDebouncedSearch } from '../../hooks/useDebouncedSearch.ts';
import { useResizeHandle } from '../../hooks/useResizeHandle.ts';
import { useErrorKeys, useErrorMessages } from '../../hooks/useValidation.ts';
import AddItemDialog from '../AddItemDialog.tsx';
import ConfirmDialog from '../ConfirmDialog.tsx';
import EmptyState from '../EmptyState.tsx';
import ResizeHandle from '../ResizeHandle.tsx';
import SharedParamEditor from './SharedParamEditor.tsx';

const PAGE_SIZE = 20;

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

  const errorKeys = useErrorKeys();
  const errorMessages = useErrorMessages();
  const { searchInput, search, isPending: isSearchPending, handleSearchChange } = useDebouncedSearch();
  const [isExpandPending, startTransition] = useTransition();
  const isPending = isSearchPending || isExpandPending;
  const [addFileOpen, setAddFileOpen] = useState(false);
  const [addParamOpen, setAddParamOpen] = useState<number | null>(null);
  const [collapsedFiles, setCollapsedFiles] = useState<Set<number>>(new Set());
  const [confirmDelete, setConfirmDelete] = useState<{ title: string; message: string; action: () => void } | null>(null);
  const [visibleLimits, setVisibleLimits] = useState<Record<number, number>>({});
  const { width: sidebarWidth, dragging, atLimit, containerRef: sidebarRef, handleMouseDown } = useResizeHandle({
    initialWidth: 240, storageKey: 'studio-sidebar-shared',
  });

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
    startTransition(() => {
      setCollapsedFiles((prev) => {
        const next = new Set(prev);
        if (next.has(i)) next.delete(i); else next.add(i);
        return next;
      });
    });
  };
  const allExpanded = files.length > 0 && collapsedFiles.size === 0;
  const expandAllFiles = () => startTransition(() => setCollapsedFiles(new Set()));
  const collapseAllFiles = () => startTransition(() => setCollapsedFiles(new Set(files.map((_, i) => i))));

  const isSel = (fi: number, p?: string) =>
    selectedPath?.tab === 'shared' && selectedPath.fileIndex === fi && selectedPath.parameter === p;

  const fileMatchesSearch = (fi: number) => {
    if (!q) return true;
    const file = files[fi];
    if (file.fileName.toLowerCase().includes(q)) return true;
    return Object.keys(file.parameters).some((pn) => pn.toLowerCase().includes(q));
  };

  return (
    <Box sx={{ display: 'flex', height: '100%', mx: -3, mt: -1 }}>
      <Box ref={sidebarRef} sx={{
        width: sidebarWidth, minWidth: 200, borderRight: 1, borderColor: 'divider', overflow: 'auto', flexShrink: 0,
        ...sidebarScroll,
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
              value={searchInput}
              onChange={(e) => handleSearchChange(e.target.value)}
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
            <Typography sx={{ fontSize: '0.78rem', color: 'text.disabled', lineHeight: 1.5, px: 1, mb: 1.5 }}>
              Define once, reference from any event. Use <code>null</code> in events to link.
            </Typography>
            <Box sx={{
              mx: 1, mb: 2, p: 1.5, borderRadius: 2, bgcolor: '#1E1E1E', textAlign: 'left',
              fontFamily: '"JetBrains Mono", monospace', fontSize: '0.7rem', lineHeight: 1.7, color: '#D4D4D4',
            }}>
              <Box><Box component="span" sx={{ color: '#5C5C5C' }}># shared_user.yaml</Box></Box>
              <Box><Box component="span" sx={{ color: '#DF4926' }}>session_id</Box><Box component="span" sx={{ color: '#5C5C5C' }}>:</Box></Box>
              <Box>  <Box component="span" sx={{ color: '#DF4926' }}>type</Box><Box component="span" sx={{ color: '#5C5C5C' }}>:</Box><Box component="span" sx={{ color: '#D4D4D4' }}> string</Box></Box>
              <Box>  <Box component="span" sx={{ color: '#DF4926' }}>required</Box><Box component="span" sx={{ color: '#5C5C5C' }}>:</Box><Box component="span" sx={{ color: '#E8A84E' }}> true</Box></Box>
            </Box>
            <Button size="small" variant="contained" onClick={() => setAddFileOpen(true)} sx={{ fontSize: '0.78rem' }}>
              Add your first file
            </Button>
          </Box>
        )}
        <Box sx={{ position: 'relative' }}>
          {isPending && (
            <Box sx={{ position: 'absolute', inset: 0, zIndex: 2, display: 'flex', justifyContent: 'center', pt: 4 }}>
              <CircularProgress size={20} sx={{ color: '#DF4926' }} />
            </Box>
          )}
        <List dense disablePadding sx={{ px: 0.5, pb: 1, ...(isPending && { opacity: 0.4, pointerEvents: 'none' }) }}>
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
                    primary={<><Box component="span" sx={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{file.fileName}</Box><Typography component="span" sx={{ fontSize: '0.78rem', color: 'text.disabled', ml: 0.5, flexShrink: 0 }}>{Object.keys(file.parameters).length || ''}</Typography>{errorKeys.has(`shared:${fi}`) && <Tooltip title={errorMessages.get(`shared:${fi}`)?.join('; ') ?? ''} arrow enterDelay={200} placement="right"><Box component="span" sx={{ width: 6, height: 6, borderRadius: '50%', bgcolor: '#D32F2F', display: 'inline-block', flexShrink: 0, ml: 0.5 }} /></Tooltip>}</>}
                    primaryTypographyProps={{ fontSize: '0.85rem', fontWeight: 600 }}
                    sx={{ minWidth: 0, '& .MuiListItemText-primary': { display: 'flex', alignItems: 'center', overflow: 'hidden' } }}
                  />
                  <Tooltip title="Delete file" arrow enterDelay={400}>
                    <IconButton size="small" onClick={(e) => {
                      e.stopPropagation();
                      setConfirmDelete({ title: `Delete ${file.fileName}?`, message: 'All parameters in this file will be removed.', action: () => removeSharedParamFile(fi) });
                    }} sx={hoverDelete}>
                      <DeleteOutlineRounded sx={{ fontSize: 16 }} />
                    </IconButton>
                  </Tooltip>
                </ListItemButton>
                <Collapse in={isFileExpanded(fi) || !!q} timeout={150} unmountOnExit>
                  <List dense disablePadding>
                    {(() => {
                      const paramKeys = Object.keys(file.parameters).filter((pn) =>
                        !q || pn.toLowerCase().includes(q) || file.fileName.toLowerCase().includes(q)
                      );
                      const limit = q ? paramKeys.length : (visibleLimits[fi] ?? PAGE_SIZE);
                      const visible = paramKeys.slice(0, limit);
                      const remaining = paramKeys.length - limit;
                      return (
                        <>
                          {visible.map((pn) => {
                            const uses = usageCounts[pn] ?? 0;
                            const hasErr = errorKeys.has(`shared:${fi}:${pn}`);
                            return (
                              <ListItemButton key={pn} sx={{
                                pl: 5.5, py: 0.4,
                                ...(isSel(fi, pn) && { bgcolor: alpha('#DF4926', 0.06) }),
                              }} onClick={() => setSelectedPath({ tab: 'shared', fileIndex: fi, parameter: pn })}>
                                <ListItemIcon sx={{ minWidth: 18 }}>
                                  <CircleRounded sx={{ fontSize: 6, color: hasErr ? '#D32F2F' : 'text.disabled' }} />
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
                                      {hasErr && <Tooltip title={errorMessages.get(`shared:${fi}:${pn}`)?.join('; ') ?? ''} arrow enterDelay={200} placement="right"><Box component="span" sx={{ width: 6, height: 6, borderRadius: '50%', bgcolor: '#D32F2F', display: 'inline-block', flexShrink: 0 }} /></Tooltip>}
                                    </Box>
                                  }
                                  primaryTypographyProps={{
                                    fontSize: '0.78rem', fontFamily: '"JetBrains Mono", monospace',
                                  }}
                                />
                                <Tooltip title="Delete" arrow enterDelay={400}>
                                  <IconButton size="small" onClick={(e) => {
                                    e.stopPropagation();
                                    setConfirmDelete({ title: `Delete "${pn}"?`, message: `This will remove the shared parameter "${pn}".`, action: () => removeSharedParam(fi, pn) });
                                  }} sx={hoverDelete}>
                                    <DeleteOutlineRounded sx={{ fontSize: 15 }} />
                                  </IconButton>
                                </Tooltip>
                              </ListItemButton>
                            );
                          })}
                          {remaining > 0 && (
                            <ListItemButton sx={{ pl: 5.5, py: 0.5, justifyContent: 'center' }}
                              onClick={() => setVisibleLimits((prev) => ({ ...prev, [fi]: Math.min((prev[fi] ?? PAGE_SIZE) + PAGE_SIZE, paramKeys.length) }))} dense>
                              <Typography sx={{ fontSize: '0.75rem', color: '#DF4926', fontWeight: 600 }}>
                                Show {remaining} more parameter{remaining > 1 ? 's' : ''}...
                              </Typography>
                            </ListItemButton>
                          )}
                          {!q && (
                            <ListItemButton sx={{ pl: 5.5, ...addItemButton }} onClick={() => setAddParamOpen(fi)}>
                              <AddRounded sx={{ fontSize: 15, color: '#DF4926', mr: 0.5 }} />
                              <ListItemText primary="Add Parameter" primaryTypographyProps={{
                                fontSize: '0.78rem', color: '#DF4926', fontWeight: 600,
                              }} />
                            </ListItemButton>
                          )}
                        </>
                      );
                    })()}
                  </List>
                </Collapse>
              </Box>
            );
          })}
        </List>
        </Box>
        {q && files.length > 0 && files.every((_, fi) => !fileMatchesSearch(fi)) && (
          <Typography sx={{ px: 2, py: 3, textAlign: 'center', fontSize: '0.78rem', color: 'text.disabled' }}>
            No matches for "{searchInput}"
          </Typography>
        )}
      </Box>
      <ResizeHandle dragging={dragging} atLimit={atLimit} onMouseDown={handleMouseDown} />
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
