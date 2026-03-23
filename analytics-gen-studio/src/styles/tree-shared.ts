/** Shared style constants for tree sidebars (Events, Shared Params, Contexts) */

export const hoverAction = {
  opacity: 0, transition: 'opacity 0.1s', color: 'text.disabled',
  p: 0.5, flexShrink: 0,
  '&:hover': { color: 'primary.main', bgcolor: (t: { palette: { primary: { main: string } } }) => `${t.palette.primary.main}0F`, opacity: 1 },
  '.MuiListItemButton-root:hover &, .MuiListItemButton-root:focus-within &': { opacity: 1 },
  '&:focus-visible': { opacity: 1, outline: '2px solid', outlineColor: 'primary.main', outlineOffset: 1 },
} as const;

export const hoverEdit = {
  opacity: 0, transition: 'opacity 0.1s', color: 'text.disabled',
  p: 0.3, flexShrink: 0,
  '&:hover': { color: 'primary.main', bgcolor: (t: { palette: { primary: { main: string } } }) => `${t.palette.primary.main}0F`, opacity: 1 },
  '.MuiListItemButton-root:hover &, .MuiListItemButton-root:focus-within &': { opacity: 0.7 },
  '&:focus-visible': { opacity: 1, outline: '2px solid', outlineColor: 'primary.main', outlineOffset: 1 },
} as const;

export const hoverDelete = {
  opacity: 0, transition: 'opacity 0.15s', color: 'text.disabled',
  p: 0.5, flexShrink: 0,
  '&:hover': { color: 'error.main', bgcolor: (t: { palette: { error: { main: string } } }) => `${t.palette.error.main}0F`, opacity: 1 },
  '.MuiListItemButton-root:hover &, .MuiListItemButton-root:focus-within &': { opacity: 1 },
  '&:focus-visible': { opacity: 1, outline: '2px solid', outlineColor: 'error.main', outlineOffset: 1 },
} as const;

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
