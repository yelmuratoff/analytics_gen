import Box from '@mui/material/Box';

interface ResizeHandleProps {
  dragging: boolean;
  onMouseDown: () => void;
}

export default function ResizeHandle({ dragging, onMouseDown }: ResizeHandleProps) {
  return (
    <Box
      role="separator"
      aria-label="Resize panels"
      onMouseDown={onMouseDown}
      sx={{
        width: 8,
        cursor: 'col-resize',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        flexShrink: 0,
        '&:hover .dot': { bgcolor: '#DF4926', opacity: 0.7 },
      }}
    >
      <Box sx={{ display: 'flex', flexDirection: 'column', gap: '3px' }}>
        {[0, 1, 2].map((i) => (
          <Box key={i} className="dot" sx={{
            width: 3,
            height: 3,
            borderRadius: '50%',
            bgcolor: dragging ? '#DF4926' : 'text.disabled',
            opacity: dragging ? 0.7 : 0.25,
          }} />
        ))}
      </Box>
    </Box>
  );
}
