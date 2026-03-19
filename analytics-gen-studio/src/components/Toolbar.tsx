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
import BookmarkAddRounded from '@mui/icons-material/BookmarkAddRounded';
import RefreshRounded from '@mui/icons-material/RefreshRounded';
import { useStore } from '../state/store.ts';
import { exportAllAsZip, saveProject, loadProjectFile } from '../utils/export.ts';

export default function Toolbar() {
  const [confirmOpen, setConfirmOpen] = useState(false);
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

  const actionBtn = { color: '#999', '&:hover': { color: '#DF4926', bgcolor: 'rgba(223,73,38,0.04)' } };

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
          <Tooltip title="Export ZIP (Ctrl+Shift+E)" arrow>
            <IconButton onClick={handleExportZip} size="small" sx={actionBtn}>
              <FolderZipRounded sx={{ fontSize: 20 }} />
            </IconButton>
          </Tooltip>
          <Tooltip title="Save Project (Ctrl+S)" arrow>
            <IconButton onClick={handleSaveProject} size="small" sx={actionBtn}>
              <BookmarkAddRounded sx={{ fontSize: 20 }} />
            </IconButton>
          </Tooltip>
          <Tooltip title="Open Project (Ctrl+O)" arrow>
            <IconButton onClick={() => fileInputRef.current?.click()} size="small" sx={actionBtn}>
              <FileOpenRounded sx={{ fontSize: 20 }} />
            </IconButton>
          </Tooltip>
          <input ref={fileInputRef} type="file" accept=".json" style={{ display: 'none' }} onChange={handleLoadProject} />
          <Box sx={{ width: 1, height: 20, bgcolor: '#E8E4E0', mx: 0.5 }} />
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

      <Snackbar
        open={!!snackbar}
        autoHideDuration={2500}
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
