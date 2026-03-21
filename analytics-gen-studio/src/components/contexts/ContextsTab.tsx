import { useState, useCallback, useRef } from 'react';
import Box from '@mui/material/Box';
import List from '@mui/material/List';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemText from '@mui/material/ListItemText';
import ListItemIcon from '@mui/material/ListItemIcon';
import IconButton from '@mui/material/IconButton';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import Collapse from '@mui/material/Collapse';
import Dialog from '@mui/material/Dialog';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import DialogActions from '@mui/material/DialogActions';
import TextField from '@mui/material/TextField';
import InputAdornment from '@mui/material/InputAdornment';
import InsertDriveFileRounded from '@mui/icons-material/InsertDriveFileRounded';
import FolderRounded from '@mui/icons-material/FolderRounded';
import CircleRounded from '@mui/icons-material/CircleRounded';
import KeyboardArrowRightRounded from '@mui/icons-material/KeyboardArrowRightRounded';
import KeyboardArrowDownRounded from '@mui/icons-material/KeyboardArrowDownRounded';
import DeleteOutlineRounded from '@mui/icons-material/DeleteOutlineRounded';
import AddRounded from '@mui/icons-material/AddRounded';
import LayersRounded from '@mui/icons-material/LayersRounded';
import SearchRounded from '@mui/icons-material/SearchRounded';
import UnfoldMoreRounded from '@mui/icons-material/UnfoldMoreRounded';
import UnfoldLessRounded from '@mui/icons-material/UnfoldLessRounded';
import Tooltip from '@mui/material/Tooltip';
import { alpha } from '@mui/material/styles';
import type { RJSFSchema } from '@rjsf/utils';
import { useStore } from '../../state/store.ts';
import { SNAKE_CASE_PARAM, DEFAULT_PARAM_TYPE } from '../../schemas/constants.ts';
import AddItemDialog from '../AddItemDialog.tsx';
import ConfirmDialog from '../ConfirmDialog.tsx';
import EmptyState from '../EmptyState.tsx';
import ContextPropertyEditor from './ContextPropertyEditor.tsx';

function deriveContextName(fileName: string): string {
  return fileName.replace(/\.yaml$/, '').replace(/[^a-z0-9_]/g, '_').replace(/^[^a-z]/, '').replace(/_+/g, '_').replace(/_$/, '');
}

interface ContextsTabProps {
  parameterSchema: RJSFSchema;
  operations: string[];
}

export default function ContextsTab({ parameterSchema, operations }: ContextsTabProps) {
  const files = useStore((s) => s.contextFiles);
  const selectedPath = useStore((s) => s.selectedPath);
  const setSelectedPath = useStore((s) => s.setSelectedPath);
  const addContextFile = useStore((s) => s.addContextFile);
  const removeContextFile = useStore((s) => s.removeContextFile);
  const addContextProperty = useStore((s) => s.addContextProperty);
  const removeContextProperty = useStore((s) => s.removeContextProperty);

  const [search, setSearch] = useState('');
  const [addFileOpen, setAddFileOpen] = useState(false);
  const [fileNameInput, setFileNameInput] = useState('');
  const [contextNameInput, setContextNameInput] = useState('');
  const [addPropOpen, setAddPropOpen] = useState<number | null>(null);
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
      const sidebar = document.querySelector('[data-contexts-sidebar]') as HTMLElement;
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
    selectedPath?.tab === 'contexts' && selectedPath.fileIndex === fi && selectedPath.contextProperty === p;

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

  const [fileError, setFileError] = useState('');
  const [ctxError, setCtxError] = useState('');

  const handleAddFile = () => {
    const fn = fileNameInput.trim();
    const cn = contextNameInput.trim();
    if (!fn) { setFileError('File name is required'); return; }
    if (!/^[a-zA-Z0-9_.\-/]+$/.test(fn)) { setFileError('Invalid characters'); return; }
    if (!cn) { setCtxError('Context name is required'); return; }
    if (!SNAKE_CASE_PARAM.test(cn)) { setCtxError('Must be snake_case'); return; }
    if (files.some((f) => f.fileName === (fn.endsWith('.yaml') ? fn : `${fn}.yaml`))) { setFileError('File already exists'); return; }
    addContextFile(fn.endsWith('.yaml') ? fn : `${fn}.yaml`, cn);
    setFileNameInput(''); setContextNameInput('');
    setFileError(''); setCtxError('');
    setAddFileOpen(false);
  };

  const fileMatchesSearch = (fi: number) => {
    if (!q) return true;
    const file = files[fi];
    if (file.fileName.toLowerCase().includes(q)) return true;
    if (file.contextName.toLowerCase().includes(q)) return true;
    return Object.keys(file.properties).some((pn) => pn.toLowerCase().includes(q));
  };

  return (
    <Box sx={{ display: 'flex', height: '100%', mx: -3, mt: -1 }}>
      <Box data-contexts-sidebar sx={{
        width: sidebarWidth, minWidth: 200, borderRight: 1, borderColor: 'divider', overflow: 'auto', flexShrink: 0,
        '&::-webkit-scrollbar': { width: 5 },
        '&::-webkit-scrollbar-thumb': { bgcolor: 'text.disabled', opacity: 0.5, borderRadius: 3 },
      }}>
        <Box sx={{ p: 1.5, display: 'flex', flexDirection: 'column', gap: 1 }}>
          <Box sx={{ display: 'flex', gap: 0.5 }}>
            <Button startIcon={<AddRounded />} size="small" onClick={() => setAddFileOpen(true)}
              fullWidth variant="outlined" sx={{ fontSize: '0.82rem', py: 0.5 }}>
              Add Context
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
              placeholder={files.length > 0 ? 'Search...' : 'Add a context to search'}
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
              bgcolor: 'rgba(99,102,241,0.06)', border: '2px dashed', borderColor: '#6366F1',
            }}>
              <LayersRounded sx={{ fontSize: 28, color: '#6366F1' }} />
            </Box>
            <Typography sx={{ fontSize: '0.85rem', color: 'text.secondary', mb: 0.5, fontWeight: 600 }}>No contexts yet</Typography>
            <Typography sx={{ fontSize: '0.78rem', color: 'text.disabled', lineHeight: 1.5, px: 1, mb: 2 }}>
              Contexts group properties that are set/updated during the app lifecycle.
            </Typography>
            <Button size="small" variant="contained" onClick={() => setAddFileOpen(true)} sx={{ fontSize: '0.78rem' }}>
              Add your first context
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
                    <InsertDriveFileRounded sx={{ fontSize: 17, color: '#6366F1' }} />
                  </ListItemIcon>
                  <ListItemText
                    primary={<>{file.fileName}<Typography component="span" sx={{ fontSize: '0.78rem', color: 'text.disabled', ml: 0.5 }}>{Object.keys(file.properties).length || ''}</Typography></>}
                    primaryTypographyProps={{ fontSize: '0.85rem', fontWeight: 600 }}
                  />
                  <IconButton size="small" onClick={(e) => {
                    e.stopPropagation();
                    setConfirmDelete({ title: `Delete ${file.fileName}?`, message: 'All properties in this context will be removed.', action: () => removeContextFile(fi) });
                  }} sx={hoverDel}>
                    <DeleteOutlineRounded sx={{ fontSize: 16 }} />
                  </IconButton>
                </ListItemButton>
                <Collapse in={isFileExpanded(fi) || !!q}>
                  <List dense disablePadding>
                    <ListItemButton sx={{ pl: 5, py: 0.3 }} dense>
                      <ListItemIcon sx={{ minWidth: 20 }}>
                        <FolderRounded sx={{ fontSize: 16, color: '#DF4926' }} />
                      </ListItemIcon>
                      <ListItemText primary={file.contextName} primaryTypographyProps={{
                        fontSize: '0.82rem', fontWeight: 600, color: '#DF4926',
                      }} />
                    </ListItemButton>
                    {Object.keys(file.properties).map((pn) => {
                      if (q && !pn.toLowerCase().includes(q) && !file.fileName.toLowerCase().includes(q) && !file.contextName.toLowerCase().includes(q)) return null;
                      return (
                        <ListItemButton key={pn} sx={{
                          pl: 7, py: 0.4,
                          ...(isSel(fi, pn) && { bgcolor: alpha('#DF4926', 0.06) }),
                        }} onClick={() => setSelectedPath({ tab: 'contexts', fileIndex: fi, contextProperty: pn })}>
                          <ListItemIcon sx={{ minWidth: 18 }}>
                            <CircleRounded sx={{ fontSize: 6, color: 'text.disabled' }} />
                          </ListItemIcon>
                          <ListItemText primary={pn} primaryTypographyProps={{
                            fontSize: '0.78rem', fontFamily: '"JetBrains Mono", monospace',
                          }} />
                          <IconButton size="small" onClick={(e) => {
                            e.stopPropagation();
                            setConfirmDelete({ title: `Delete "${pn}"?`, message: `This will remove the property "${pn}" from context "${file.contextName}".`, action: () => removeContextProperty(fi, pn) });
                          }} sx={hoverDel}>
                            <DeleteOutlineRounded sx={{ fontSize: 15 }} />
                          </IconButton>
                        </ListItemButton>
                      );
                    })}
                    {!q && (
                      <ListItemButton sx={{ pl: 7, ...addBtnSx }} onClick={() => setAddPropOpen(fi)}>
                        <AddRounded sx={{ fontSize: 15, color: '#DF4926', mr: 0.5 }} />
                        <ListItemText primary="Add Property" primaryTypographyProps={{
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
      </Box>
      {/* Resize handle */}
      <Box
        role="separator"
        aria-label="Resize sidebar"
        onMouseDown={handleMouseDown}
        sx={{
          width: 12, cursor: 'col-resize', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
          '&:hover .ctx-line': { opacity: 1, bgcolor: '#DF4926' },
        }}
      >
        <Box className="ctx-line" sx={{
          width: 3, height: 32, borderRadius: 2,
          bgcolor: dragging ? '#DF4926' : 'text.disabled',
          opacity: dragging ? 1 : 0.4,
          transition: 'all 0.15s ease',
        }} />
      </Box>
      <Box sx={{ flex: 1, overflow: 'auto', p: 3 }}>
        {selectedPath?.tab === 'contexts' && selectedPath.contextProperty ? (
          <ContextPropertyEditor fileIndex={selectedPath.fileIndex} propName={selectedPath.contextProperty} parameterSchema={parameterSchema} operations={operations} />
        ) : (
          <EmptyState
            icon={<LayersRounded sx={{ fontSize: 28, color: '#6366F1' }} />}
            title="Select a property"
            description="Context properties track state across the app lifecycle. Select operations and configure type."
            accentColor="#6366F1"
          />
        )}
      </Box>

      <Dialog open={addFileOpen} onClose={() => setAddFileOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle sx={{ fontWeight: 700, pb: 0.5 }}>Add Context</DialogTitle>
        <DialogContent sx={{ pt: '12px !important' }}>
          <TextField autoFocus fullWidth size="small" margin="dense" label="File name"
            placeholder="user_properties.yaml" value={fileNameInput}
            error={!!fileError} helperText={fileError}
            onChange={(e) => {
              const fn = e.target.value;
              setFileNameInput(fn); setFileError('');
              if (!contextNameInput || contextNameInput === deriveContextName(fileNameInput)) {
                setContextNameInput(deriveContextName(fn));
                setCtxError('');
              }
            }} sx={{ mt: 1 }} />
          <TextField fullWidth size="small" margin="dense" label="Context name"
            placeholder="user_properties" value={contextNameInput}
            error={!!ctxError} helperText={ctxError}
            onChange={(e) => { setContextNameInput(e.target.value); setCtxError(''); }}
            onKeyDown={(e) => { if (e.key === 'Enter') handleAddFile(); }} />
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2.5 }}>
          <Button onClick={() => setAddFileOpen(false)} variant="outlined" size="small">Cancel</Button>
          <Button onClick={handleAddFile} variant="contained" size="small"
            disabled={!fileNameInput.trim() || !contextNameInput.trim()}>Add</Button>
        </DialogActions>
      </Dialog>

      {addPropOpen !== null && (
        <AddItemDialog open title="Add Property" label="Name" placeholder="user_id"
          validateSnakeCase existingNames={Object.keys(files[addPropOpen]?.properties ?? {})}
          onClose={() => setAddPropOpen(null)}
          onAdd={(n) => {
            addContextProperty(addPropOpen, n, { type: DEFAULT_PARAM_TYPE });
            setSelectedPath({ tab: 'contexts', fileIndex: addPropOpen, contextProperty: n });
            setAddPropOpen(null);
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
