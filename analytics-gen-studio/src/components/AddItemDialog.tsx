import { useState } from 'react';
import Dialog from '@mui/material/Dialog';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import DialogActions from '@mui/material/DialogActions';
import TextField from '@mui/material/TextField';
import Button from '@mui/material/Button';
import Typography from '@mui/material/Typography';

interface AddItemDialogProps {
  open: boolean;
  title: string;
  label: string;
  placeholder?: string;
  existingNames?: string[];
  onClose: () => void;
  onAdd: (name: string) => void;
}

export default function AddItemDialog({ open, title, label, placeholder, existingNames = [], onClose, onAdd }: AddItemDialogProps) {
  const [value, setValue] = useState('');
  const [error, setError] = useState('');

  const handleAdd = () => {
    const trimmed = value.trim();
    if (!trimmed) {
      setError('Name cannot be empty');
      return;
    }
    if (existingNames.includes(trimmed)) {
      setError('Name already exists');
      return;
    }
    onAdd(trimmed);
    setValue('');
    setError('');
    onClose();
  };

  const handleClose = () => {
    setValue('');
    setError('');
    onClose();
  };

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="xs" fullWidth>
      <DialogTitle sx={{ pb: 0.5 }}>
        <Typography variant="h6" component="span">{title}</Typography>
      </DialogTitle>
      <DialogContent sx={{ pt: '12px !important' }}>
        <TextField
          autoFocus
          fullWidth
          size="small"
          label={label}
          placeholder={placeholder}
          value={value}
          onChange={(e) => { setValue(e.target.value); setError(''); }}
          error={!!error}
          helperText={error}
          onKeyDown={(e) => { if (e.key === 'Enter') handleAdd(); }}
          sx={{ mt: 1 }}
        />
      </DialogContent>
      <DialogActions sx={{ px: 3, pb: 2.5 }}>
        <Button onClick={handleClose} variant="outlined" size="small">Cancel</Button>
        <Button onClick={handleAdd} variant="contained" size="small">Add</Button>
      </DialogActions>
    </Dialog>
  );
}
