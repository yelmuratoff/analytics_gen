import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import { useTheme } from '@mui/material/styles';

interface EmptyStateProps {
  icon: React.ReactNode;
  title: string;
  description: string;
  actionLabel?: string;
  onAction?: () => void;
  /** Accent color — hex value or palette path like 'brand.events'. Defaults to divider. */
  accentColor?: string;
}

/** Resolve a dot-path like 'brand.events' against the palette, or return the string as-is if it's a hex. */
function resolveColor(palette: Record<string, unknown>, path: string): string {
  if (path.startsWith('#') || path.startsWith('rgb')) return path;
  const parts = path.split('.');
  let obj: unknown = palette;
  for (const p of parts) {
    if (obj && typeof obj === 'object') obj = (obj as Record<string, unknown>)[p];
    else return path;
  }
  return typeof obj === 'string' ? obj : path;
}

export default function EmptyState({ icon, title, description, actionLabel, onAction, accentColor }: EmptyStateProps) {
  const { palette } = useTheme();
  const color = accentColor ? resolveColor(palette as unknown as Record<string, unknown>, accentColor) : undefined;

  return (
    <Box sx={{
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      height: '100%', gap: 1, py: 6,
    }}>
      <Box sx={{
        width: 64, height: 64, borderRadius: '50%',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        bgcolor: color ? `${color}08` : 'action.hover',
        border: '2px dashed',
        borderColor: color ?? 'divider',
        mb: 1,
      }}>
        {icon}
      </Box>
      <Typography sx={{ fontWeight: 600, fontSize: '0.88rem', color: 'text.secondary' }}>
        {title}
      </Typography>
      <Typography sx={{ fontSize: '0.78rem', color: 'text.disabled', lineHeight: 1.6, textAlign: 'center', maxWidth: 260 }}>
        {description}
      </Typography>
      {actionLabel && onAction && (
        <Button onClick={onAction} variant="contained" size="small" sx={{ mt: 1.5, fontSize: '0.82rem' }}>
          {actionLabel}
        </Button>
      )}
    </Box>
  );
}
