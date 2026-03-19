import { useState } from 'react';
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
import InsertDriveFileRounded from '@mui/icons-material/InsertDriveFileRounded';
import FolderRounded from '@mui/icons-material/FolderRounded';
import CircleRounded from '@mui/icons-material/CircleRounded';
import KeyboardArrowRightRounded from '@mui/icons-material/KeyboardArrowRightRounded';
import KeyboardArrowDownRounded from '@mui/icons-material/KeyboardArrowDownRounded';
import CloseRounded from '@mui/icons-material/CloseRounded';
import AddRounded from '@mui/icons-material/AddRounded';
import LayersRounded from '@mui/icons-material/LayersRounded';
import { alpha } from '@mui/material/styles';
import type { RJSFSchema } from '@rjsf/utils';
import { useStore } from '../../state/store.ts';
import AddItemDialog from '../AddItemDialog.tsx';
import ConfirmDialog from '../ConfirmDialog.tsx';
import ContextPropertyEditor from './ContextPropertyEditor.tsx';

interface ContextsTabProps {
  parameterSchema: RJSFSchema;
}

export default function ContextsTab({ parameterSchema }: ContextsTabProps) {
  const files = useStore((s) => s.contextFiles);
  const selectedPath = useStore((s) => s.selectedPath);
  const setSelectedPath = useStore((s) => s.setSelectedPath);
  const addContextFile = useStore((s) => s.addContextFile);
  const removeContextFile = useStore((s) => s.removeContextFile);
  const addContextProperty = useStore((s) => s.addContextProperty);
  const removeContextProperty = useStore((s) => s.removeContextProperty);

  const [addFileOpen, setAddFileOpen] = useState(false);
  const [fileNameInput, setFileNameInput] = useState('');
  const [contextNameInput, setContextNameInput] = useState('');
  const [addPropOpen, setAddPropOpen] = useState<number | null>(null);
  const [collapsedFiles, setCollapsedFiles] = useState<Set<number>>(new Set());
  const [confirmDelete, setConfirmDelete] = useState<{ title: string; message: string; action: () => void } | null>(null);

  const isFileExpanded = (i: number) => !collapsedFiles.has(i);
  const toggleExpand = (i: number) => {
    setCollapsedFiles((prev) => {
      const next = new Set(prev);
      if (next.has(i)) next.delete(i); else next.add(i);
      return next;
    });
  };

  const isSel = (fi: number, p?: string) =>
    selectedPath?.tab === 'contexts' && selectedPath.fileIndex === fi && selectedPath.contextProperty === p;

  const hoverDel = {
    opacity: 0, transition: 'opacity 0.1s', color: '#BCBCBC',
    '&:hover': { color: '#D32F2F' },
    '.MuiListItemButton-root:hover &': { opacity: 1 },
  };

  const [fileError, setFileError] = useState('');
  const [ctxError, setCtxError] = useState('');

  const handleAddFile = () => {
    const fn = fileNameInput.trim();
    const cn = contextNameInput.trim();
    if (!fn) { setFileError('File name is required'); return; }
    if (!/^[a-zA-Z0-9_.\-/]+$/.test(fn)) { setFileError('Invalid characters'); return; }
    if (!cn) { setCtxError('Context name is required'); return; }
    if (!/^[a-z][a-z0-9_]*$/.test(cn)) { setCtxError('Must be snake_case'); return; }
    if (files.some((f) => f.fileName === (fn.endsWith('.yaml') ? fn : `${fn}.yaml`))) { setFileError('File already exists'); return; }
    addContextFile(fn.endsWith('.yaml') ? fn : `${fn}.yaml`, cn);
    setFileNameInput(''); setContextNameInput('');
    setFileError(''); setCtxError('');
    setAddFileOpen(false);
  };

  return (
    <Box sx={{ display: 'flex', height: '100%', mx: -3, mt: -1 }}>
      <Box sx={{ width: 240, minWidth: 200, borderRight: '1px solid #EEEBE8', overflow: 'auto' }}>
        <Box sx={{ p: 1.5 }}>
          <Button startIcon={<AddRounded />} size="small" onClick={() => setAddFileOpen(true)}
            fullWidth variant="outlined" sx={{ fontSize: '0.78rem', py: 0.5 }}>
            Add Context
          </Button>
        </Box>
        {files.length === 0 && (
          <Box sx={{ px: 2, py: 4, textAlign: 'center' }}>
            <LayersRounded sx={{ fontSize: 30, color: '#E8E4E0', mb: 0.5 }} />
            <Typography sx={{ fontSize: '0.75rem', color: '#BCBCBC' }}>No contexts yet</Typography>
          </Box>
        )}
        <List dense disablePadding sx={{ px: 0.5, pb: 1 }}>
          {files.map((file, fi) => (
            <Box key={fi}>
              <ListItemButton onClick={() => toggleExpand(fi)} dense sx={{ py: 0.4 }}>
                {isFileExpanded(fi) ? <KeyboardArrowDownRounded sx={{ fontSize: 18, color: '#999' }} />
                  : <KeyboardArrowRightRounded sx={{ fontSize: 18, color: '#ccc' }} />}
                <ListItemIcon sx={{ minWidth: 26, ml: 0.2 }}>
                  <InsertDriveFileRounded sx={{ fontSize: 17, color: '#6366F1' }} />
                </ListItemIcon>
                <ListItemText
                  primary={<>{file.fileName}<Typography component="span" sx={{ fontSize: '0.62rem', color: '#bbb', ml: 0.5 }}>{Object.keys(file.properties).length || ''}</Typography></>}
                  primaryTypographyProps={{ fontSize: '0.82rem', fontWeight: 600 }}
                />
                <IconButton size="small" onClick={(e) => {
                  e.stopPropagation();
                  setConfirmDelete({ title: `Delete ${file.fileName}?`, message: 'All properties in this context will be removed.', action: () => removeContextFile(fi) });
                }} sx={hoverDel}>
                  <CloseRounded sx={{ fontSize: 14 }} />
                </IconButton>
              </ListItemButton>
              <Collapse in={isFileExpanded(fi)}>
                <List dense disablePadding>
                  <ListItemButton sx={{ pl: 5, py: 0.3 }} dense>
                    <ListItemIcon sx={{ minWidth: 20 }}>
                      <FolderRounded sx={{ fontSize: 16, color: '#DF4926' }} />
                    </ListItemIcon>
                    <ListItemText primary={file.contextName} primaryTypographyProps={{
                      fontSize: '0.78rem', fontWeight: 600, color: '#DF4926',
                    }} />
                  </ListItemButton>
                  {Object.keys(file.properties).map((pn) => (
                    <ListItemButton key={pn} sx={{
                      pl: 7, py: 0.3,
                      ...(isSel(fi, pn) && { bgcolor: alpha('#DF4926', 0.06) }),
                    }} onClick={() => setSelectedPath({ tab: 'contexts', fileIndex: fi, contextProperty: pn })}>
                      <ListItemIcon sx={{ minWidth: 18 }}>
                        <CircleRounded sx={{ fontSize: 6, color: '#ccc' }} />
                      </ListItemIcon>
                      <ListItemText primary={pn} primaryTypographyProps={{
                        fontSize: '0.76rem', fontFamily: '"JetBrains Mono", monospace',
                      }} />
                      <IconButton size="small" onClick={(e) => { e.stopPropagation(); removeContextProperty(fi, pn); }} sx={hoverDel}>
                        <CloseRounded sx={{ fontSize: 13 }} />
                      </IconButton>
                    </ListItemButton>
                  ))}
                  <ListItemButton sx={{ pl: 7, py: 0.2 }} onClick={() => setAddPropOpen(fi)}>
                    <AddRounded sx={{ fontSize: 15, color: '#DF4926', mr: 0.5 }} />
                    <ListItemText primary="Add Property" primaryTypographyProps={{
                      fontSize: '0.74rem', color: '#DF4926', fontWeight: 600,
                    }} />
                  </ListItemButton>
                </List>
              </Collapse>
            </Box>
          ))}
        </List>
      </Box>
      <Box sx={{ flex: 1, overflow: 'auto', p: 3 }}>
        {selectedPath?.tab === 'contexts' && selectedPath.contextProperty ? (
          <ContextPropertyEditor fileIndex={selectedPath.fileIndex} propName={selectedPath.contextProperty} parameterSchema={parameterSchema} />
        ) : (
          <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '100%' }}>
            <LayersRounded sx={{ fontSize: 36, color: '#E8E4E0', mb: 1 }} />
            <Typography sx={{ fontSize: '0.82rem', color: '#BCBCBC' }}>Select a property</Typography>
          </Box>
        )}
      </Box>

      <Dialog open={addFileOpen} onClose={() => setAddFileOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle sx={{ fontWeight: 700, pb: 0.5 }}>Add Context</DialogTitle>
        <DialogContent sx={{ pt: '12px !important' }}>
          <TextField autoFocus fullWidth size="small" margin="dense" label="File name"
            placeholder="user_properties.yaml" value={fileNameInput}
            error={!!fileError} helperText={fileError}
            onChange={(e) => { setFileNameInput(e.target.value); setFileError(''); }} sx={{ mt: 1 }} />
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
            addContextProperty(addPropOpen, n, { type: 'string' });
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
