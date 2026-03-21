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
import CircularProgress from '@mui/material/CircularProgress';
import Snackbar from '@mui/material/Snackbar';
import Alert from '@mui/material/Alert';
import FolderZipRounded from '@mui/icons-material/FolderZipRounded';
import FileOpenRounded from '@mui/icons-material/FileOpenRounded';
import SaveRounded from '@mui/icons-material/SaveRounded';
import SaveAsRounded from '@mui/icons-material/SaveAsRounded';
import RefreshRounded from '@mui/icons-material/RefreshRounded';
import MenuBookRounded from '@mui/icons-material/MenuBookRounded';
import KeyboardArrowDownRounded from '@mui/icons-material/KeyboardArrowDownRounded';
import MoreVertRounded from '@mui/icons-material/MoreVertRounded';
import InsertDriveFileRounded from '@mui/icons-material/InsertDriveFileRounded';
import KeyboardRounded from '@mui/icons-material/KeyboardRounded';
import DarkModeRounded from '@mui/icons-material/DarkModeRounded';
import LightModeRounded from '@mui/icons-material/LightModeRounded';
import Divider from '@mui/material/Divider';
import { useStore } from '../state/store.ts';
import { useColorMode } from '../App.tsx';
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

const shortcuts = [
  { keys: `${mod}S`, description: 'Save project' },
  { keys: `${mod}\u21E7S`, description: 'Save As...' },
  { keys: `${mod}O`, description: 'Open project' },
  { keys: `${mod}\u21E7E`, description: 'Export ZIP' },
  { keys: `${mod}1\u20134`, description: 'Switch tabs' },
];

export default function Toolbar() {
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [docsOpen, setDocsOpen] = useState(false);
  const [shortcutsOpen, setShortcutsOpen] = useState(false);
  const [fileMenuAnchor, setFileMenuAnchor] = useState<HTMLElement | null>(null);
  const [moreMenuAnchor, setMoreMenuAnchor] = useState<HTMLElement | null>(null);
  const [snackbar, setSnackbar] = useState<{ message: string; severity: 'success' | 'error' } | null>(null);
  const [saving, setSaving] = useState(false);
  const [fileName, setFileName] = useState<string | null>(null);
  const [isDirty, setIsDirty] = useState(false);
  const [lastSavedSnapshot, setLastSavedSnapshot] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const store = useStore();
  const { mode, toggleColorMode } = useColorMode();

  const handleExportZip = useCallback(() => {
    exportAllAsZip(store);
    setSnackbar({ message: 'ZIP exported', severity: 'success' });
  }, [store]);

  const handleSave = useCallback(async () => {
    setSaving(true);
    try {
      const result = await saveProject(store);
      if (result.saved) {
        setFileName(result.fileName);
        setLastSavedSnapshot(currentSnapshot);
        setSnackbar({ message: `Saved${result.fileName ? ` \u2192 ${result.fileName}` : ''}`, severity: 'success' });
      }
    } catch (err) {
      setSnackbar({ message: `Save failed: ${err instanceof Error ? err.message : 'Unknown error'}`, severity: 'error' });
    } finally {
      setSaving(false);
    }
  }, [store]);

  const handleSaveAs = useCallback(async () => {
    setSaving(true);
    try {
      const name = await saveProjectAs(store);
      if (name) {
        setFileName(name);
        setLastSavedSnapshot(currentSnapshot);
        setSnackbar({ message: `Saved \u2192 ${name}`, severity: 'success' });
      }
    } catch (err) {
      setSnackbar({ message: `Save failed: ${err instanceof Error ? err.message : 'Unknown error'}`, severity: 'error' });
    } finally {
      setSaving(false);
    }
  }, [store]);

  const handleOpen = useCallback(async () => {
    if (supportsFileSystemAccess) {
      try {
        const result = await openProject();
        if (result) {
          store.loadProject(result.data);
          setFileName(result.fileName);
          setTimeout(() => setLastSavedSnapshot(JSON.stringify({
            config: useStore.getState().config,
            eventFiles: useStore.getState().eventFiles,
            sharedParamFiles: useStore.getState().sharedParamFiles,
            contextFiles: useStore.getState().contextFiles,
          })), 0);
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
      setTimeout(() => setLastSavedSnapshot(JSON.stringify({
        config: useStore.getState().config,
        eventFiles: useStore.getState().eventFiles,
        sharedParamFiles: useStore.getState().sharedParamFiles,
        contextFiles: useStore.getState().contextFiles,
      })), 0);
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
    setLastSavedSnapshot(null);
    setConfirmOpen(false);
    setSnackbar({ message: 'Reset complete', severity: 'success' });
  };

  useEffect(() => {
    const name = getCurrentFileName();
    if (name) setFileName(name);
  }, []);

  const currentSnapshot = JSON.stringify({
    config: store.config,
    eventFiles: store.eventFiles,
    sharedParamFiles: store.sharedParamFiles,
    contextFiles: store.contextFiles,
  });
  const dirty = lastSavedSnapshot !== null && currentSnapshot !== lastSavedSnapshot;
  if (dirty !== isDirty) setIsDirty(dirty);

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
    fontSize: '0.82rem',
    color: 'text.secondary',
    borderColor: 'transparent',
    whiteSpace: 'nowrap',
    '&:hover': { color: '#DF4926', bgcolor: 'rgba(223,73,38,0.04)', borderColor: 'transparent' },
  };

  return (
    <>
      <Box sx={{
        display: 'flex', alignItems: 'center',
        px: 3, py: 0.8,
        bgcolor: 'background.paper',
        borderBottom: 1, borderColor: 'divider',
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
            <InsertDriveFileRounded sx={{ fontSize: 14, color: 'text.disabled' }} />
            <Typography sx={{
              fontSize: '0.78rem', color: 'text.secondary', fontFamily: '"JetBrains Mono", monospace',
              maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
            }}>
              {fileName}{isDirty && <Box component="span" sx={{ color: '#DF4926', ml: 0.75 }}>●</Box>}
            </Typography>
          </Box>
        )}
        {!fileName && <Box sx={{ flex: 1 }} />}

        {/* Actions */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
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

          {/* Save button with dropdown for Save As */}
          <Box sx={{ display: 'flex' }}>
            <Tooltip title={`Save${fileName ? ` \u2192 ${fileName}` : ''} (${mod}S)`} arrow>
              <Button
                onClick={handleSave}
                disabled={saving}
                size="small"
                variant="outlined"
                startIcon={saving ? <CircularProgress size={14} sx={{ color: 'text.secondary' }} /> : <SaveRounded sx={{ fontSize: 18 }} />}
                sx={{
                  ...actionBtnSx,
                  borderTopRightRadius: 0,
                  borderBottomRightRadius: 0,
                  pr: 1,
                }}
              >
                {saving ? 'Saving...' : 'Save'}
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
                  borderLeft: 1,
                  borderLeftColor: 'divider',
                  minWidth: 32,
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
                primaryTypographyProps={{ fontSize: '0.85rem' }}
                secondaryTypographyProps={{ fontSize: '0.72rem' }} />
            </MenuItem>
            <MenuItem onClick={() => { setFileMenuAnchor(null); handleSaveAs(); }}>
              <ListItemIcon><SaveAsRounded sx={{ fontSize: 18 }} /></ListItemIcon>
              <ListItemText primary="Save As..." secondary={`${mod}\u21E7S`}
                primaryTypographyProps={{ fontSize: '0.85rem' }}
                secondaryTypographyProps={{ fontSize: '0.72rem' }} />
            </MenuItem>
          </Menu>

          <Tooltip title={`Export ZIP (${mod}\u21E7E)`} arrow>
            <Button
              onClick={handleExportZip}
              size="small"
              variant="contained"
              startIcon={<FolderZipRounded sx={{ fontSize: 18 }} />}
              sx={{ fontSize: '0.82rem', whiteSpace: 'nowrap', px: 2, py: 0.6 }}
            >
              Export
            </Button>
          </Tooltip>

          <Divider orientation="vertical" flexItem sx={{ mx: 0.5 }} />

          <Tooltip title={mode === 'light' ? 'Dark mode' : 'Light mode'} arrow>
            <IconButton onClick={toggleColorMode} size="small" sx={{
              color: 'text.secondary', '&:hover': { color: '#DF4926', bgcolor: 'rgba(223,73,38,0.04)' },
            }}>
              {mode === 'light' ? <DarkModeRounded sx={{ fontSize: 20 }} /> : <LightModeRounded sx={{ fontSize: 20 }} />}
            </IconButton>
          </Tooltip>

          <Tooltip title="More options" arrow>
            <IconButton onClick={(e) => setMoreMenuAnchor(e.currentTarget)} size="small" sx={{
              color: 'text.secondary', '&:hover': { color: 'text.primary', bgcolor: 'action.hover' },
            }}>
              <MoreVertRounded sx={{ fontSize: 20 }} />
            </IconButton>
          </Tooltip>
          <Menu
            anchorEl={moreMenuAnchor}
            open={!!moreMenuAnchor}
            onClose={() => setMoreMenuAnchor(null)}
            slotProps={{ paper: { sx: { borderRadius: 3, minWidth: 180 } } }}
          >
            <MenuItem onClick={() => { setMoreMenuAnchor(null); setDocsOpen(true); }}>
              <ListItemIcon><MenuBookRounded sx={{ fontSize: 18 }} /></ListItemIcon>
              <ListItemText primary="API Docs" primaryTypographyProps={{ fontSize: '0.85rem' }} />
            </MenuItem>
            <MenuItem onClick={() => { setMoreMenuAnchor(null); setShortcutsOpen(true); }}>
              <ListItemIcon><KeyboardRounded sx={{ fontSize: 18 }} /></ListItemIcon>
              <ListItemText primary="Keyboard Shortcuts" primaryTypographyProps={{ fontSize: '0.85rem' }} />
            </MenuItem>
            <Divider />
            <MenuItem onClick={() => { setMoreMenuAnchor(null); setConfirmOpen(true); }} sx={{
              color: 'error.main', '&:hover': { bgcolor: 'rgba(211,47,47,0.04)' },
            }}>
              <ListItemIcon><RefreshRounded sx={{ fontSize: 18, color: '#D32F2F' }} /></ListItemIcon>
              <ListItemText primary="Reset All" primaryTypographyProps={{ fontSize: '0.85rem' }} />
            </MenuItem>
          </Menu>
        </Box>
      </Box>

      <Dialog open={confirmOpen} onClose={() => setConfirmOpen(false)} maxWidth="xs">
        <DialogTitle sx={{ fontWeight: 700, pb: 0.5 }}>Reset everything?</DialogTitle>
        <DialogContent>
          <DialogContentText sx={{ fontSize: '0.88rem' }}>
            All tabs will be cleared and restored to defaults. This cannot be undone.
          </DialogContentText>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2.5 }}>
          <Button onClick={() => setConfirmOpen(false)} variant="outlined" size="small">Cancel</Button>
          <Button onClick={handleReset} variant="contained" size="small"
            sx={{ bgcolor: '#D32F2F', '&:hover': { bgcolor: '#B71C1C' } }}>Reset</Button>
        </DialogActions>
      </Dialog>

      {/* Keyboard Shortcuts Dialog */}
      <Dialog open={shortcutsOpen} onClose={() => setShortcutsOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle sx={{ fontWeight: 700, pb: 1 }}>Keyboard Shortcuts</DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5 }}>
            {shortcuts.map((s) => (
              <Box key={s.keys} sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Typography sx={{ fontSize: '0.85rem', color: 'text.primary' }}>{s.description}</Typography>
                <Box sx={{
                  px: 1.2, py: 0.3, borderRadius: 1.5,
                  bgcolor: 'action.hover',
                  border: 1, borderColor: 'divider',
                }}>
                  <Typography sx={{
                    fontSize: '0.78rem', fontWeight: 600, fontFamily: '"JetBrains Mono", monospace',
                    color: 'text.secondary',
                  }}>
                    {s.keys}
                  </Typography>
                </Box>
              </Box>
            ))}
          </Box>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2.5 }}>
          <Button onClick={() => setShortcutsOpen(false)} variant="outlined" size="small">Close</Button>
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
