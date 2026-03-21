import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';

interface BreadcrumbProps {
  parts: string[];
  onPartClick?: (index: number) => void;
}

export default function Breadcrumb({ parts, onPartClick }: BreadcrumbProps) {
  if (parts.length <= 1) return null;

  return (
    <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, flexWrap: 'nowrap', overflow: 'hidden' }}>
      {parts.map((part, i) => {
        const isLast = i === parts.length - 1;
        const isClickable = !isLast && i >= 1 && !!onPartClick;
        return (
          <Box key={i} sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
            {i > 0 && (
              <Typography sx={{ fontSize: isLast ? '0.85rem' : '0.78rem', color: 'text.disabled', mx: 0.2 }}>/</Typography>
            )}
            <Typography
              component={isClickable ? 'button' : 'span'}
              onClick={isClickable ? () => onPartClick(i) : undefined}
              onKeyDown={isClickable ? (e: React.KeyboardEvent) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); onPartClick(i); } } : undefined}
              tabIndex={isClickable ? 0 : undefined}
              sx={{
                fontSize: isLast ? '1.05rem' : '0.82rem',
                color: isLast ? 'text.primary' : 'text.secondary',
                fontWeight: isLast ? 700 : 400,
                fontFamily: '"JetBrains Mono", monospace',
                background: 'none', border: 'none', p: 0, borderRadius: 0.5,
                overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
                maxWidth: isLast ? 'none' : 120, flexShrink: isLast ? 0 : 1,
                ...(isClickable && {
                  cursor: 'pointer',
                  '&:hover': { color: '#DF4926' },
                  '&:focus-visible': { outline: '2px solid #DF4926', outlineOffset: 2 },
                }),
              }}>
              {part}
            </Typography>
          </Box>
        );
      })}
    </Box>
  );
}
