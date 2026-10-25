/** Shared constants for tree sidebars (Events, Shared Params, Contexts) */

/** Number of items shown before "Show more" pagination button */
export const PAGE_SIZE = 20;

export const addItemButton = {
  py: 0.3,
  opacity: 0.7,
  borderTop: '1px dashed',
  borderColor: 'divider',
  borderRadius: 0,
  mx: 1,
  mt: 0.5,
  '&:hover': { opacity: 1, bgcolor: (t: { palette: { primary: { main: string } } }) => `${t.palette.primary.main}0A` },
} as const;

export const truncatedText = {
  minWidth: 0,
  '& .MuiListItemText-primary': { display: 'flex', alignItems: 'center', overflow: 'hidden' },
} as const;

export const truncatedName = {
  overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
} as const;

export const sidebarScroll = {
  scrollbarWidth: 'thin' as const,
  scrollbarColor: 'rgba(0,0,0,0.15) transparent',
  '&::-webkit-scrollbar': { width: 5 },
  '&::-webkit-scrollbar-thumb': { bgcolor: 'text.disabled', opacity: 0.5, borderRadius: 3 },
} as const;
