import { useState } from 'react';
import { SNAKE_CASE_PARAM } from '../schemas/constants.ts';
import Dialog from '@mui/material/Dialog';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import DialogActions from '@mui/material/DialogActions';
import TextField from '@mui/material/TextField';
import Button from '@mui/material/Button';
import Typography from '@mui/material/Typography';

// Characters that break YAML keys or are unsafe
const YAML_UNSAFE = /[:{}\[\]&*?|><!%@`#,'"\\]/;
const VALID_YAML_KEY = /^[a-zA-Z_][a-zA-Z0-9_./-]*$/;

interface AddItemDialogProps {
  open: boolean;
  title: string;
  label: string;
  placeholder?: string;
  existingNames?: string[];
  validateSnakeCase?: boolean;
  isFileName?: boolean;
  onClose: () => void;
  onAdd: (name: string) => void;
}

export default function AddItemDialog({ open, title, label, placeholder, existingNames = [], validateSnakeCase, isFileName, onClose, onAdd }: AddItemDialogProps) {
  const [value, setValue] = useState('');
  const [error, setError] = useState('');

  const validate = (input: string): string | null => {
    if (!input) return 'Name cannot be empty';
    if (existingNames.includes(input)) return 'Name already exists';

    if (isFileName) {
      // File names: allow alphanumeric, _, -, ., /
      if (!/^[a-zA-Z0-9_.\-/]+$/.test(input)) {
        return 'Invalid characters. Use letters, numbers, _, -, .';
      }
    } else {
      // YAML keys
      if (YAML_UNSAFE.test(input)) {
        return 'Contains characters that break YAML (: { } [ ] etc.)';
      }
      if (!VALID_YAML_KEY.test(input)) {
        return 'Must start with a letter or _, only letters, numbers, _';
      }
      if (validateSnakeCase && !SNAKE_CASE_PARAM.test(input)) {
        return 'Must be snake_case (lowercase, numbers, underscores)';
      }
    }

    if (input.length > 100) return 'Name is too long (max 100 characters)';

    return null;
  };

  const handleAdd = () => {
    const trimmed = value.trim();
    const err = validate(trimmed);
    if (err) {
      setError(err);
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
