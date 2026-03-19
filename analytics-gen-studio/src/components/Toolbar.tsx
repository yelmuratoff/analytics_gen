import { useRef, useState, useEffect, useCallback } from 'react';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import IconButton from '@mui/material/IconButton';
import Tooltip from '@mui/material/Tooltip';
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
import RefreshRounded from '@mui/icons-material/RefreshRounded';
import MenuBookRounded from '@mui/icons-material/MenuBookRounded';
import { useStore } from '../state/store.ts';
import { exportAllAsZip, saveProject, loadProjectFile } from '../utils/export.ts';
import DocsDrawer from './DocsDrawer.tsx';

const isMac = typeof navigator !== 'undefined' && /Mac/.test(navigator.platform);

export default function Toolbar() {
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [docsOpen, setDocsOpen] = useState(false);
  const [snackbar, setSnackbar] = useState<{ message: string; severity: 'success' | 'error' } | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const store = useStore();

  const handleExportZip = useCallback(() => {
    exportAllAsZip(store);
    setSnackbar({ message: 'ZIP exported', severity: 'success' });
  }, [store]);

  const handleSaveProject = useCallback(() => {
    saveProject(store);
    setSnackbar({ message: 'Project saved', severity: 'success' });
  }, [store]);

  const handleLoadProject = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      const data = await loadProjectFile(file);
      store.loadProject(data);
      setSnackbar({ message: 'Project loaded', severity: 'success' });
    } catch (err) {
      setSnackbar({ message: `Failed to load: ${err instanceof Error ? err.message : 'Unknown error'}`, severity: 'error' });
    }
    if (fileInputRef.current) fileInputRef.current.value = '';
  };

  const handleReset = () => {
    store.resetState();
    setConfirmOpen(false);
    setSnackbar({ message: 'Reset complete', severity: 'success' });
  };

  // Keyboard shortcuts
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      const mod = e.metaKey || e.ctrlKey;
      if (!mod) return;
      if (e.key === 's') {
        e.preventDefault();
        handleSaveProject();
      } else if (e.key === 'e' && e.shiftKey) {
        e.preventDefault();
        handleExportZip();
      } else if (e.key === 'o') {
        e.preventDefault();
        fileInputRef.current?.click();
      }
    };
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, [handleSaveProject, handleExportZip]);

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
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mr: 'auto' }}>
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
          <Tooltip title={`Export ZIP (${isMac ? '\u2318\u21E7E' : 'Ctrl+Shift+E'})`} arrow>
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
          <Tooltip title={`Save Project (${isMac ? '\u2318S' : 'Ctrl+S'})`} arrow>
            <Button
              onClick={handleSaveProject}
              size="small"
              variant="outlined"
              startIcon={<SaveRounded sx={{ fontSize: 18 }} />}
              sx={actionBtnSx}
            >
              Save
            </Button>
          </Tooltip>
          <Tooltip title={`Open Project (${isMac ? '\u2318O' : 'Ctrl+O'})`} arrow>
            <IconButton onClick={() => fileInputRef.current?.click()} size="small" sx={{
              color: '#999', '&:hover': { color: '#DF4926', bgcolor: 'rgba(223,73,38,0.04)' },
            }}>
              <FileOpenRounded sx={{ fontSize: 20 }} />
            </IconButton>
          </Tooltip>
          <input ref={fileInputRef} type="file" accept=".json" style={{ display: 'none' }} onChange={handleLoadProject} />
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
