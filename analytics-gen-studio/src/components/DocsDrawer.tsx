import Box from '@mui/material/Box';
import Drawer from '@mui/material/Drawer';
import IconButton from '@mui/material/IconButton';
import Typography from '@mui/material/Typography';
import Tooltip from '@mui/material/Tooltip';
import CloseRounded from '@mui/icons-material/CloseRounded';
import OpenInNewRounded from '@mui/icons-material/OpenInNewRounded';

interface DocsDrawerProps {
  open: boolean;
  onClose: () => void;
}

const DOCS_PATH = `${import.meta.env.BASE_URL}docs/index.html`;

export default function DocsDrawer({ open, onClose }: DocsDrawerProps) {
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
            bgcolor: '#FCFDF7',
            borderLeft: '1px solid #EEEBE8',
          },
        },
      }}
    >
      <Box sx={{
        display: 'flex', alignItems: 'center', gap: 1,
        px: 2.5, py: 1.5,
        borderBottom: '1px solid #EEEBE8',
        bgcolor: '#FCFDF7',
      }}>
        <Typography sx={{ fontWeight: 700, fontSize: '0.95rem', flex: 1 }}>
          API Documentation
        </Typography>
        <Tooltip title="Open in new tab" arrow>
          <IconButton size="small" onClick={() => window.open(DOCS_PATH, '_blank')} sx={{
            color: '#999', '&:hover': { color: '#DF4926', bgcolor: 'rgba(223,73,38,0.04)' },
          }}>
            <OpenInNewRounded sx={{ fontSize: 18 }} />
          </IconButton>
        </Tooltip>
        <Tooltip title="Close" arrow>
          <IconButton size="small" onClick={onClose} sx={{
            color: '#999', '&:hover': { color: '#1A1A1A', bgcolor: 'rgba(0,0,0,0.04)' },
          }}>
            <CloseRounded sx={{ fontSize: 20 }} />
          </IconButton>
        </Tooltip>
      </Box>
      <Box
        component="iframe"
        src={DOCS_PATH}
        sx={{
          flex: 1, border: 'none', width: '100%', height: '100%',
          bgcolor: '#fff',
        }}
      />
    </Drawer>
  );
}
