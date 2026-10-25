import Box from '@mui/material/Box';
import Tooltip from '@mui/material/Tooltip';

interface ErrorDotProps {
  messages?: string[];
  ml?: number;
}

export default function ErrorDot({ messages, ml = 0.5 }: ErrorDotProps) {
  const label = messages?.length ? messages.join('; ') : 'Validation error';
  const dot = (
    <Box component="span" role="img" aria-label={label} sx={{
      width: 6, height: 6, borderRadius: '50%', bgcolor: 'error.main',
      display: 'inline-block', flexShrink: 0, ml,
    }} />
  );
  if (!messages?.length) return dot;
  return <Tooltip title={label} arrow enterDelay={200} placement="right">{dot}</Tooltip>;
}
