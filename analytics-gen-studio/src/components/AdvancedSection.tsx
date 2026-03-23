import { useState } from 'react';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Collapse from '@mui/material/Collapse';
import TuneRounded from '@mui/icons-material/TuneRounded';
import KeyboardArrowDownRounded from '@mui/icons-material/KeyboardArrowDownRounded';
import KeyboardArrowRightRounded from '@mui/icons-material/KeyboardArrowRightRounded';

interface AdvancedSectionProps {
  setCount: number;
  children: React.ReactNode;
  defaultOpen?: boolean;
}

export default function AdvancedSection({ setCount, children, defaultOpen = false }: AdvancedSectionProps) {
  const [open, setOpen] = useState(defaultOpen);

  return (
    <Box sx={{ borderRadius: 2, border: 1, borderColor: 'divider', overflow: 'hidden' }}>
      <Box
        role="button"
        tabIndex={0}
        aria-expanded={open}
        onClick={() => setOpen(!open)}
        onKeyDown={(e: React.KeyboardEvent) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); setOpen(!open); } }}
        sx={{
          display: 'flex', alignItems: 'center', gap: 1, py: 1, px: 2,
          cursor: 'pointer', userSelect: 'none',
          bgcolor: open ? (t: { palette: { primary: { main: string } } }) => `${t.palette.primary.main}05` : 'transparent',
          '&:hover': { bgcolor: (t: { palette: { primary: { main: string } } }) => `${t.palette.primary.main}0A` },
          '&:focus-visible': { outline: '2px solid', outlineColor: 'primary.main', outlineOffset: -2, borderRadius: 2 },
        }}
      >
        {open
          ? <KeyboardArrowDownRounded sx={{ fontSize: 20, color: 'primary.main' }} />
          : <KeyboardArrowRightRounded sx={{ fontSize: 20, color: 'text.secondary' }} />}
        <TuneRounded sx={{ fontSize: 16, color: open ? 'primary.main' : 'text.secondary' }} />
        <Typography sx={{ fontWeight: 600, fontSize: '0.82rem', color: 'text.secondary', flex: 1 }}>
          Advanced Options
        </Typography>
        {setCount > 0 && !open && (
          <Box sx={{ px: 0.8, py: 0.15, borderRadius: 1, bgcolor: 'rgba(46,125,50,0.08)' }}>
            <Typography sx={{ fontSize: '0.7rem', fontWeight: 600, color: 'success.main' }}>
              {setCount} set
            </Typography>
          </Box>
        )}
      </Box>
      <Collapse in={open}>
        <Box sx={{ px: 2, pb: 2, pt: 1 }}>
          {children}
        </Box>
      </Collapse>
    </Box>
  );
}
