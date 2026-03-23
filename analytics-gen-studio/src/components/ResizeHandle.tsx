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
        '&:hover': { bgcolor: 'rgba(223,73,38,0.06)' },
        '&:hover .dot': { bgcolor: '#DF4926', opacity: 0.8 },
        ...(dragging && !atLimit && { bgcolor: 'rgba(223,73,38,0.06)' }),
        ...(dragging && atLimit && { bgcolor: 'rgba(211,47,47,0.08)' }),
      }}
    >
      <Box sx={{ display: 'flex', flexDirection: 'column', gap: '3px' }}>
        {[0, 1, 2].map((i) => (
          <Box key={i} className="dot" sx={{
            width: 3,
            height: 3,
            borderRadius: '50%',
            bgcolor: dragging ? (atLimit ? '#D32F2F' : '#DF4926') : 'text.disabled',
            opacity: dragging ? 0.8 : 0.25,
            transition: 'all 0.15s',
          }} />
        ))}
      </Box>
    </Box>
  );
}
