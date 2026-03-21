import Box from '@mui/material/Box';

interface ResizeHandleProps {
  dragging: boolean;
  onMouseDown: () => void;
  width?: number;
}

export default function ResizeHandle({ dragging, onMouseDown, width = 16 }: ResizeHandleProps) {
  return (
    <Box
      role="separator"
      aria-label="Resize panels"
      onMouseDown={onMouseDown}
      sx={{
        width,
        cursor: 'col-resize',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        flexShrink: 0,
        '&:hover .grip-dot': { bgcolor: '#DF4926', opacity: 1 },
      }}
    >
      <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(2, 4px)', gap: '3px' }}>
        {[...Array(6)].map((_, i) => (
          <Box
            key={i}
            className="grip-dot"
            sx={{
              width: 4,
              height: 4,
              borderRadius: '50%',
              bgcolor: dragging ? '#DF4926' : 'text.disabled',
              opacity: dragging ? 1 : 0.35,
              transition: 'all 0.15s ease',
            }}
          />
        ))}
      </Box>
    </Box>
  );
}
