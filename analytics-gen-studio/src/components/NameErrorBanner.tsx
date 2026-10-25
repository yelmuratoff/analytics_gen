import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import ErrorOutlineRounded from '@mui/icons-material/ErrorOutlineRounded';

interface NameErrorBannerProps {
  message: string | null;
}

export default function NameErrorBanner({ message }: NameErrorBannerProps) {
  if (!message) return null;
  return (
    <Box role="alert" sx={{
      mt: 1.5, px: 2, py: 1.2, borderRadius: 1.5,
      bgcolor: 'rgba(211,47,47,0.06)', border: '1px solid rgba(211,47,47,0.2)',
      display: 'flex', alignItems: 'center', gap: 0.75,
    }}>
      <ErrorOutlineRounded sx={{ fontSize: 14, color: 'error.main', flexShrink: 0 }} />
      <Typography sx={{ fontSize: '0.78rem', color: 'error.main', fontWeight: 500 }}>{message}</Typography>
    </Box>
  );
}
