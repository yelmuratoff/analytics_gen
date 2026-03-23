import Dialog from '@mui/material/Dialog';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import DialogContentText from '@mui/material/DialogContentText';
import DialogActions from '@mui/material/DialogActions';
import Button from '@mui/material/Button';
import Box from '@mui/material/Box';
import WarningAmberRounded from '@mui/icons-material/WarningAmberRounded';

interface ConfirmDialogProps {
  open: boolean;
  title: string;
  message: string;
  confirmLabel?: string;
  onConfirm: () => void;
  onCancel: () => void;
}

export default function ConfirmDialog({ open, title, message, confirmLabel = 'Delete', onConfirm, onCancel }: ConfirmDialogProps) {
  return (
    <Dialog open={open} onClose={onCancel} maxWidth="xs">
      <DialogTitle sx={{ fontWeight: 700, pb: 0.5, display: 'flex', alignItems: 'center', gap: 1.5 }}>
        <Box sx={{
          width: 40, height: 40, borderRadius: '50%',
          bgcolor: (t: { palette: { error: { main: string } } }) => `${t.palette.error.main}1F`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          flexShrink: 0,
        }}>
          <WarningAmberRounded sx={{ fontSize: 22, color: 'error.main' }} />
        </Box>
        {title}
      </DialogTitle>
      <DialogContent>
        <DialogContentText sx={{ fontSize: '0.85rem', pl: 6.5 }}>{message}</DialogContentText>
      </DialogContent>
      <DialogActions sx={{ px: 3, pb: 2.5 }}>
        <Button onClick={onCancel} variant="outlined" size="small">Cancel</Button>
        <Button onClick={onConfirm} variant="contained" size="small"
          sx={{ bgcolor: 'error.main', '&:hover': { bgcolor: 'error.dark' } }}>{confirmLabel}</Button>
      </DialogActions>
    </Dialog>
  );
}
