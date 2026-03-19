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
import TextField from '@mui/material/TextField';
import InputAdornment from '@mui/material/InputAdornment';
import InsertDriveFileRounded from '@mui/icons-material/InsertDriveFileRounded';
import CircleRounded from '@mui/icons-material/CircleRounded';
import KeyboardArrowRightRounded from '@mui/icons-material/KeyboardArrowRightRounded';
import KeyboardArrowDownRounded from '@mui/icons-material/KeyboardArrowDownRounded';
import CloseRounded from '@mui/icons-material/CloseRounded';
import AddRounded from '@mui/icons-material/AddRounded';
import ShareRounded from '@mui/icons-material/ShareRounded';
import SearchRounded from '@mui/icons-material/SearchRounded';
import { alpha } from '@mui/material/styles';
import type { RJSFSchema } from '@rjsf/utils';
import { useStore } from '../../state/store.ts';
import { DEFAULT_PARAM_TYPE } from '../../schemas/constants.ts';
import AddItemDialog from '../AddItemDialog.tsx';
import ConfirmDialog from '../ConfirmDialog.tsx';
import SharedParamEditor from './SharedParamEditor.tsx';

interface SharedParamsTabProps {
  parameterSchema: RJSFSchema;
}

export default function SharedParamsTab({ parameterSchema }: SharedParamsTabProps) {
  const files = useStore((s) => s.sharedParamFiles);
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

  const q = search.toLowerCase();

  const isFileExpanded = (i: number) => !collapsedFiles.has(i);
  const toggleExpand = (i: number) => {
    setCollapsedFiles((prev) => {
      const next = new Set(prev);
      if (next.has(i)) next.delete(i); else next.add(i);
      return next;
    });
  };

  const isSel = (fi: number, p?: string) =>
    selectedPath?.tab === 'shared' && selectedPath.fileIndex === fi && selectedPath.parameter === p;

  const hoverDel = {
    opacity: 0, transition: 'opacity 0.1s', color: '#BCBCBC',
    '&:hover': { color: '#D32F2F' },
    '.MuiListItemButton-root:hover &': { opacity: 1 },
  };

  const fileMatchesSearch = (fi: number) => {
    if (!q) return true;
    const file = files[fi];
    if (file.fileName.toLowerCase().includes(q)) return true;
    return Object.keys(file.parameters).some((pn) => pn.toLowerCase().includes(q));
  };

  return (
    <Box sx={{ display: 'flex', height: '100%', mx: -3, mt: -1 }}>
      <Box sx={{ width: 240, minWidth: 200, borderRight: '1px solid #EEEBE8', overflow: 'auto' }}>
        <Box sx={{ p: 1.5, display: 'flex', flexDirection: 'column', gap: 1 }}>
          <Button startIcon={<AddRounded />} size="small" onClick={() => setAddFileOpen(true)}
            fullWidth variant="outlined" sx={{ fontSize: '0.78rem', py: 0.5 }}>
            Add File
          </Button>
          {files.length > 0 && (
            <TextField
              size="small"
              placeholder="Search..."
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
          )}
        </Box>
        {files.length === 0 && (
          <Box sx={{ px: 2, py: 4, textAlign: 'center' }}>
            <ShareRounded sx={{ fontSize: 30, color: '#E8E4E0', mb: 0.5 }} />
            <Typography sx={{ fontSize: '0.75rem', color: '#BCBCBC' }}>No files yet</Typography>
          </Box>
        )}
        <List dense disablePadding sx={{ px: 0.5, pb: 1 }}>
          {files.map((file, fi) => {
            if (!fileMatchesSearch(fi)) return null;
            return (
              <Box key={fi}>
                <ListItemButton onClick={() => toggleExpand(fi)} dense sx={{ py: 0.4 }}>
                  {isFileExpanded(fi) ? <KeyboardArrowDownRounded sx={{ fontSize: 18, color: '#999' }} />
                    : <KeyboardArrowRightRounded sx={{ fontSize: 18, color: '#ccc' }} />}
                  <ListItemIcon sx={{ minWidth: 26, ml: 0.2 }}>
                    <InsertDriveFileRounded sx={{ fontSize: 17, color: '#22A06B' }} />
                  </ListItemIcon>
                  <ListItemText
                    primary={<>{file.fileName}<Typography component="span" sx={{ fontSize: '0.62rem', color: '#bbb', ml: 0.5 }}>{Object.keys(file.parameters).length || ''}</Typography></>}
                    primaryTypographyProps={{ fontSize: '0.82rem', fontWeight: 600 }}
                  />
                  <IconButton size="small" onClick={(e) => {
                    e.stopPropagation();
                    setConfirmDelete({ title: `Delete ${file.fileName}?`, message: 'All parameters in this file will be removed.', action: () => removeSharedParamFile(fi) });
                  }} sx={hoverDel}>
                    <CloseRounded sx={{ fontSize: 14 }} />
                  </IconButton>
                </ListItemButton>
                <Collapse in={isFileExpanded(fi) || !!q}>
                  <List dense disablePadding>
                    {Object.keys(file.parameters).map((pn) => {
                      if (q && !pn.toLowerCase().includes(q) && !file.fileName.toLowerCase().includes(q)) return null;
                      return (
                        <ListItemButton key={pn} sx={{
                          pl: 5.5, py: 0.3,
                          ...(isSel(fi, pn) && { bgcolor: alpha('#DF4926', 0.06) }),
                        }} onClick={() => setSelectedPath({ tab: 'shared', fileIndex: fi, parameter: pn })}>
                          <ListItemIcon sx={{ minWidth: 18 }}>
                            <CircleRounded sx={{ fontSize: 6, color: '#ccc' }} />
                          </ListItemIcon>
                          <ListItemText primary={pn} primaryTypographyProps={{
                            fontSize: '0.76rem', fontFamily: '"JetBrains Mono", monospace',
                          }} />
                          <IconButton size="small" onClick={(e) => {
                            e.stopPropagation();
                            setConfirmDelete({ title: `Delete "${pn}"?`, message: `This will remove the shared parameter "${pn}".`, action: () => removeSharedParam(fi, pn) });
                          }} sx={hoverDel}>
                            <CloseRounded sx={{ fontSize: 13 }} />
                          </IconButton>
                        </ListItemButton>
                      );
                    })}
                    {!q && (
                      <ListItemButton sx={{ pl: 5.5, py: 0.2 }} onClick={() => setAddParamOpen(fi)}>
                        <AddRounded sx={{ fontSize: 15, color: '#DF4926', mr: 0.5 }} />
                        <ListItemText primary="Add Parameter" primaryTypographyProps={{
                          fontSize: '0.74rem', color: '#DF4926', fontWeight: 600,
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
      <Box sx={{ flex: 1, overflow: 'auto', p: 3 }}>
        {selectedPath?.tab === 'shared' && selectedPath.parameter ? (
          <SharedParamEditor fileIndex={selectedPath.fileIndex} paramName={selectedPath.parameter} parameterSchema={parameterSchema} />
        ) : (
          <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '100%' }}>
            <ShareRounded sx={{ fontSize: 36, color: '#E8E4E0', mb: 1 }} />
            <Typography sx={{ fontSize: '0.82rem', color: '#BCBCBC' }}>Select a parameter</Typography>
          </Box>
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
