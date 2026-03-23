import Box from '@mui/material/Box';

interface ResizeHandleProps {
  dragging: boolean;
  atLimit?: boolean;
  onMouseDown: () => void;
}

export default function ResizeHandle({ dragging, atLimit, onMouseDown }: ResizeHandleProps) {
  return (
    <Box
      role="separator"
      aria-orientation="vertical"
      aria-label="Resize panels"
      onMouseDown={onMouseDown}
      sx={{
        width: 12,
        cursor: 'col-resize',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        flexShrink: 0,
        transition: 'background-color 0.15s',
        borderRadius: 1,
        mx: -0.25,
        '&:hover': { bgcolor: (t: { palette: { primary: { main: string } } }) => `${t.palette.primary.main}0F` },
        '&:hover .dot': { bgcolor: 'primary.main', opacity: 0.8 },
        ...(dragging && !atLimit && { bgcolor: (t: { palette: { primary: { main: string } } }) => `${t.palette.primary.main}0F` }),
        ...(dragging && atLimit && { bgcolor: (t: { palette: { error: { main: string } } }) => `${t.palette.error.main}14` }),
      }}
    >
      <Box sx={{ display: 'flex', flexDirection: 'column', gap: '3px' }}>
        {[0, 1, 2].map((i) => (
          <Box key={i} className="dot" sx={{
            width: 3,
            height: 3,
            borderRadius: '50%',
            bgcolor: dragging ? (atLimit ? 'error.main' : 'primary.main') : 'text.disabled',
            opacity: dragging ? 0.8 : 0.25,
            transition: 'all 0.15s',
          }} />
        ))}
      </Box>
    </Box>
  );
}
