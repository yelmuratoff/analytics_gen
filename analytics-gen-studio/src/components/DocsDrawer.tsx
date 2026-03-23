import { useState } from 'react';
import Box from '@mui/material/Box';
import Drawer from '@mui/material/Drawer';
import IconButton from '@mui/material/IconButton';
import Typography from '@mui/material/Typography';
import Tooltip from '@mui/material/Tooltip';
import CircularProgress from '@mui/material/CircularProgress';
import CloseRounded from '@mui/icons-material/CloseRounded';
import OpenInNewRounded from '@mui/icons-material/OpenInNewRounded';

interface DocsDrawerProps {
  open: boolean;
  onClose: () => void;
}

const DOCS_PATH = `${import.meta.env.BASE_URL}docs/index.html`;

export default function DocsDrawer({ open, onClose }: DocsDrawerProps) {
  const [loading, setLoading] = useState(true);

  return (
    <Drawer
      anchor="right"
      open={open}
      onClose={onClose}
      slotProps={{
        paper: {
          sx: {
            width: '65vw',
            minWidth: 480,
            maxWidth: 1100,
            bgcolor: 'background.paper',
            borderLeft: 1,
            borderColor: 'divider',
            display: 'flex',
            flexDirection: 'column',
          },
        },
      }}
      onTransitionExited={() => setLoading(true)}
    >
      <Box sx={{
        display: 'flex', alignItems: 'center', gap: 1,
        px: 2.5, py: 1.5,
        borderBottom: 1,
        borderColor: 'divider',
        bgcolor: 'background.paper',
        flexShrink: 0,
      }}>
        <Typography sx={{ fontWeight: 700, fontSize: '0.95rem', flex: 1 }}>
          API Documentation
        </Typography>
        <Tooltip title="Open in new tab" arrow>
          <IconButton size="small" onClick={() => window.open(DOCS_PATH, '_blank')} sx={{
            color: 'text.secondary', '&:hover': { color: 'primary.main', bgcolor: 'action.hover' },
          }}>
            <OpenInNewRounded sx={{ fontSize: 18 }} />
          </IconButton>
        </Tooltip>
        <Tooltip title="Close" arrow>
          <IconButton size="small" onClick={onClose} sx={{
            color: 'text.secondary', '&:hover': { color: 'text.primary', bgcolor: 'action.hover' },
          }}>
            <CloseRounded sx={{ fontSize: 20 }} />
          </IconButton>
        </Tooltip>
      </Box>
      <Box sx={{ flex: 1, position: 'relative' }}>
        {loading && (
          <Box sx={{
            position: 'absolute', inset: 0,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            bgcolor: 'background.paper', zIndex: 1, pointerEvents: 'none',
          }}>
            <CircularProgress size={28} thickness={4} sx={{ color: 'primary.main' }} />
          </Box>
        )}
        <Box
          component="iframe"
          src={DOCS_PATH}
          onLoad={() => setLoading(false)}
          sx={{
            width: '100%', height: '100%', border: 'none',
            bgcolor: 'background.paper',
          }}
        />
      </Box>
    </Drawer>
  );
}
