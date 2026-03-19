import { useRef, useState, useEffect, useCallback } from 'react';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import IconButton from '@mui/material/IconButton';
import Tooltip from '@mui/material/Tooltip';
import Menu from '@mui/material/Menu';
import MenuItem from '@mui/material/MenuItem';
import ListItemIcon from '@mui/material/ListItemIcon';
import ListItemText from '@mui/material/ListItemText';
import Dialog from '@mui/material/Dialog';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import DialogContentText from '@mui/material/DialogContentText';
import DialogActions from '@mui/material/DialogActions';
import Snackbar from '@mui/material/Snackbar';
import Alert from '@mui/material/Alert';
import FolderZipRounded from '@mui/icons-material/FolderZipRounded';
import FileOpenRounded from '@mui/icons-material/FileOpenRounded';
import SaveRounded from '@mui/icons-material/SaveRounded';
import SaveAsRounded from '@mui/icons-material/SaveAsRounded';
import RefreshRounded from '@mui/icons-material/RefreshRounded';
import MenuBookRounded from '@mui/icons-material/MenuBookRounded';
import KeyboardArrowDownRounded from '@mui/icons-material/KeyboardArrowDownRounded';
import InsertDriveFileRounded from '@mui/icons-material/InsertDriveFileRounded';
import { useStore } from '../state/store.ts';
import {
  exportAllAsZip,
  saveProject,
  saveProjectAs,
  openProject,
  loadProjectFile,
  getCurrentFileName,
  clearFileHandle,
  supportsFileSystemAccess,
} from '../utils/export.ts';
import DocsDrawer from './DocsDrawer.tsx';

const isMac = typeof navigator !== 'undefined' && /Mac/.test(navigator.platform);
const mod = isMac ? '\u2318' : 'Ctrl+';

export default function Toolbar() {
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [docsOpen, setDocsOpen] = useState(false);
  const [fileMenuAnchor, setFileMenuAnchor] = useState<HTMLElement | null>(null);
  const [snackbar, setSnackbar] = useState<{ message: string; severity: 'success' | 'error' } | null>(null);
  const [fileName, setFileName] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const store = useStore();

  const handleExportZip = useCallback(() => {
    exportAllAsZip(store);
    setSnackbar({ message: 'ZIP exported', severity: 'success' });
  }, [store]);

  const handleSave = useCallback(async () => {
    try {
      const result = await saveProject(store);
      if (result.saved) {
        setFileName(result.fileName);
        setSnackbar({ message: `Saved${result.fileName ? ` → ${result.fileName}` : ''}`, severity: 'success' });
      }
    } catch (err) {
      setSnackbar({ message: `Save failed: ${err instanceof Error ? err.message : 'Unknown error'}`, severity: 'error' });
    }
  }, [store]);

  const handleSaveAs = useCallback(async () => {
    try {
      const name = await saveProjectAs(store);
      if (name) {
        setFileName(name);
        setSnackbar({ message: `Saved → ${name}`, severity: 'success' });
      }
    } catch (err) {
      setSnackbar({ message: `Save failed: ${err instanceof Error ? err.message : 'Unknown error'}`, severity: 'error' });
    }
  }, [store]);

  const handleOpen = useCallback(async () => {
    if (supportsFileSystemAccess) {
      try {
        const result = await openProject();
        if (result) {
          store.loadProject(result.data);
          setFileName(result.fileName);
          setSnackbar({ message: `Opened ${result.fileName}`, severity: 'success' });
        }
      } catch (err) {
        setSnackbar({ message: `Failed to open: ${err instanceof Error ? err.message : 'Unknown error'}`, severity: 'error' });
      }
    } else {
      fileInputRef.current?.click();
    }
  }, [store]);

  const handleLoadFallback = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      const data = await loadProjectFile(file);
      store.loadProject(data);
      setFileName(file.name);
      setSnackbar({ message: `Opened ${file.name}`, severity: 'success' });
    } catch (err) {
      setSnackbar({ message: `Failed to load: ${err instanceof Error ? err.message : 'Unknown error'}`, severity: 'error' });
    }
    if (fileInputRef.current) fileInputRef.current.value = '';
  };

  const handleReset = () => {
    store.resetState();
    clearFileHandle();
    setFileName(null);
    setConfirmOpen(false);
    setSnackbar({ message: 'Reset complete', severity: 'success' });
  };

  // Sync fileName from handle on mount (e.g. after page restore)
  useEffect(() => {
    const name = getCurrentFileName();
    if (name) setFileName(name);
  }, []);

  // Keyboard shortcuts
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      const isMod = e.metaKey || e.ctrlKey;
      if (!isMod) return;
      if (e.key === 's' && e.shiftKey) {
        e.preventDefault();
        handleSaveAs();
      } else if (e.key === 's') {
        e.preventDefault();
        handleSave();
      } else if (e.key === 'e' && e.shiftKey) {
        e.preventDefault();
        handleExportZip();
      } else if (e.key === 'o') {
        e.preventDefault();
        handleOpen();
      }
    };
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, [handleSave, handleSaveAs, handleExportZip, handleOpen]);

  const actionBtnSx = {
    fontSize: '0.78rem',
    color: '#666',
    borderColor: 'transparent',
    whiteSpace: 'nowrap',
    '&:hover': { color: '#DF4926', bgcolor: 'rgba(223,73,38,0.04)', borderColor: 'transparent' },
  };

  return (
    <>
      <Box sx={{
        display: 'flex', alignItems: 'center',
        px: 3, py: 0.8,
        bgcolor: '#FCFDF7',
        borderBottom: '1px solid #EEEBE8',
      }}>
        {/* Brand */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mr: 2 }}>
          <Box
            component="img"
            src={`${import.meta.env.BASE_URL}logo.png`}
            alt="AnalyticsGen"
            sx={{ height: 38 }}
          />
          <Box sx={{
            px: 1, py: 0.25,
            bgcolor: 'rgba(223,73,38,0.08)', borderRadius: 1.5,
          }}>
            <Typography sx={{ fontWeight: 600, fontSize: '0.65rem', color: '#DF4926' }}>
              Studio
            </Typography>
          </Box>
        </Box>

        {/* Current file indicator */}
        {fileName && (
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mr: 'auto' }}>
            <InsertDriveFileRounded sx={{ fontSize: 14, color: '#bbb' }} />
            <Typography sx={{
              fontSize: '0.75rem', color: '#999', fontFamily: '"JetBrains Mono", monospace',
              maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
            }}>
              {fileName}
            </Typography>
          </Box>
        )}
        {!fileName && <Box sx={{ flex: 1 }} />}

        {/* Actions */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
          <Tooltip title="API Documentation" arrow>
            <Button
              onClick={() => setDocsOpen(true)}
              size="small"
              variant="outlined"
              startIcon={<MenuBookRounded sx={{ fontSize: 18 }} />}
              sx={actionBtnSx}
            >
              Docs
            </Button>
          </Tooltip>
          <Tooltip title={`Export ZIP (${mod}\u21E7E)`} arrow>
            <Button
              onClick={handleExportZip}
              size="small"
              variant="contained"
              startIcon={<FolderZipRounded sx={{ fontSize: 18 }} />}
              sx={{ fontSize: '0.78rem', whiteSpace: 'nowrap', px: 2, py: 0.6 }}
            >
              Export
            </Button>
          </Tooltip>

          {/* Save button with dropdown for Save As */}
          <Box sx={{ display: 'flex' }}>
            <Tooltip title={`Save${fileName ? ` → ${fileName}` : ''} (${mod}S)`} arrow>
              <Button
                onClick={handleSave}
                size="small"
                variant="outlined"
                startIcon={<SaveRounded sx={{ fontSize: 18 }} />}
                sx={{
                  ...actionBtnSx,
                  borderTopRightRadius: 0,
                  borderBottomRightRadius: 0,
                  pr: 1,
                }}
              >
                Save
              </Button>
            </Tooltip>
            <Tooltip title="Save options" arrow>
              <Button
                size="small"
                variant="outlined"
                onClick={(e) => setFileMenuAnchor(e.currentTarget)}
                sx={{
                  ...actionBtnSx,
                  borderTopLeftRadius: 0,
                  borderBottomLeftRadius: 0,
                  minWidth: 28,
                  px: 0.5,
                }}
              >
                <KeyboardArrowDownRounded sx={{ fontSize: 18 }} />
              </Button>
            </Tooltip>
          </Box>
          <Menu
            anchorEl={fileMenuAnchor}
            open={!!fileMenuAnchor}
            onClose={() => setFileMenuAnchor(null)}
            slotProps={{ paper: { sx: { borderRadius: 3, minWidth: 200 } } }}
          >
            <MenuItem onClick={() => { setFileMenuAnchor(null); handleSave(); }}>
              <ListItemIcon><SaveRounded sx={{ fontSize: 18 }} /></ListItemIcon>
              <ListItemText primary="Save" secondary={`${mod}S`}
                primaryTypographyProps={{ fontSize: '0.82rem' }}
                secondaryTypographyProps={{ fontSize: '0.7rem' }} />
            </MenuItem>
            <MenuItem onClick={() => { setFileMenuAnchor(null); handleSaveAs(); }}>
              <ListItemIcon><SaveAsRounded sx={{ fontSize: 18 }} /></ListItemIcon>
              <ListItemText primary="Save As..." secondary={`${mod}\u21E7S`}
                primaryTypographyProps={{ fontSize: '0.82rem' }}
                secondaryTypographyProps={{ fontSize: '0.7rem' }} />
            </MenuItem>
          </Menu>

          <Tooltip title={`Open Project (${mod}O)`} arrow>
            <Button
              onClick={handleOpen}
              size="small"
              variant="outlined"
              startIcon={<FileOpenRounded sx={{ fontSize: 18 }} />}
              sx={actionBtnSx}
            >
              Open
            </Button>
          </Tooltip>
          <input ref={fileInputRef} type="file" accept=".json" style={{ display: 'none' }} onChange={handleLoadFallback} />
          <Tooltip title="Reset All" arrow>
            <IconButton onClick={() => setConfirmOpen(true)} size="small" sx={{
              color: '#ccc', '&:hover': { color: '#D32F2F', bgcolor: 'rgba(211,47,47,0.04)' },
            }}>
              <RefreshRounded sx={{ fontSize: 20 }} />
            </IconButton>
          </Tooltip>
        </Box>
      </Box>

      <Dialog open={confirmOpen} onClose={() => setConfirmOpen(false)} maxWidth="xs">
        <DialogTitle sx={{ fontWeight: 700, pb: 0.5 }}>Reset everything?</DialogTitle>
        <DialogContent>
          <DialogContentText sx={{ fontSize: '0.85rem' }}>
            All tabs will be cleared and restored to defaults. This cannot be undone.
          </DialogContentText>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2.5 }}>
          <Button onClick={() => setConfirmOpen(false)} variant="outlined" size="small">Cancel</Button>
          <Button onClick={handleReset} variant="contained" size="small"
            sx={{ bgcolor: '#D32F2F', '&:hover': { bgcolor: '#B71C1C' } }}>Reset</Button>
        </DialogActions>
      </Dialog>

      <DocsDrawer open={docsOpen} onClose={() => setDocsOpen(false)} />

      <Snackbar
        open={!!snackbar}
        autoHideDuration={snackbar?.severity === 'error' ? 6000 : 2500}
        onClose={() => setSnackbar(null)}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        {snackbar ? (
          <Alert onClose={() => setSnackbar(null)} severity={snackbar.severity} variant="filled"
            sx={{ borderRadius: 2, minWidth: 200 }}>
            {snackbar.message}
          </Alert>
        ) : undefined}
      </Snackbar>
    </>
  );
}
