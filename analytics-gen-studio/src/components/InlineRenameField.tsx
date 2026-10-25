import TextField from '@mui/material/TextField';

interface InlineRenameFieldProps {
  value: string;
  error: string | null;
  onChange: (value: string) => void;
  onCommit: () => void;
  onCancel: () => void;
  fontSize?: string;
  height?: number;
  mono?: boolean;
}

export default function InlineRenameField({
  value, error, onChange, onCommit, onCancel, fontSize = '0.82rem', height = 24, mono = true,
}: InlineRenameFieldProps) {
  return (
    <TextField size="small" autoFocus value={value}
      onChange={(e) => onChange(e.target.value)}
      onBlur={onCommit}
      onKeyDown={(e) => { if (e.key === 'Enter') onCommit(); if (e.key === 'Escape') onCancel(); }}
      onClick={(e) => e.stopPropagation()}
      error={!!error}
      helperText={error}
      slotProps={{
        htmlInput: { 'aria-label': 'Rename' },
        input: {
          sx: {
            fontSize, py: 0, height,
            ...(mono ? { fontFamily: '"JetBrains Mono", monospace' } : {}),
            '&.Mui-focused .MuiOutlinedInput-notchedOutline': { borderWidth: 2 },
          },
        },
        formHelperText: { sx: { fontSize: '0.7rem', mx: 0 } },
      }}
      sx={{ flex: 1 }}
    />
  );
}
