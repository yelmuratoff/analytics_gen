import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';

interface EmptyStateProps {
  icon: React.ReactNode;
  title: string;
  description: string;
  actionLabel?: string;
  onAction?: () => void;
  /** Accent color for the dashed circle border. Defaults to divider. */
  accentColor?: string;
}

export default function EmptyState({ icon, title, description, actionLabel, onAction, accentColor }: EmptyStateProps) {
  return (
    <Box sx={{
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      height: '100%', gap: 1, py: 6,
    }}>
      <Box sx={{
        width: 64, height: 64, borderRadius: '50%',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        bgcolor: accentColor ? `${accentColor}08` : 'action.hover',
        border: '2px dashed',
        borderColor: accentColor ?? 'divider',
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
