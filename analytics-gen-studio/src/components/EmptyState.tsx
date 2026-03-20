import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';

interface EmptyStateProps {
  icon: React.ReactNode;
  title: string;
  description: string;
  actionLabel?: string;
  onAction?: () => void;
}

export default function EmptyState({ icon, title, description, actionLabel, onAction }: EmptyStateProps) {
  return (
    <Box sx={{
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      height: '100%', gap: 1, py: 6,
    }}>
      <Box sx={{
        width: 64, height: 64, borderRadius: '50%',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        bgcolor: 'rgba(0,0,0,0.02)', border: '2px dashed #E0DCD8', mb: 1,
      }}>
        {icon}
      </Box>
      <Typography sx={{ fontWeight: 600, fontSize: '0.85rem', color: '#999' }}>
        {title}
      </Typography>
      <Typography sx={{ fontSize: '0.75rem', color: '#bbb', lineHeight: 1.6, textAlign: 'center', maxWidth: 260 }}>
        {description}
      </Typography>
      {actionLabel && onAction && (
        <Button onClick={onAction} variant="contained" size="small" sx={{ mt: 1.5, fontSize: '0.78rem' }}>
          {actionLabel}
        </Button>
      )}
    </Box>
  );
}
