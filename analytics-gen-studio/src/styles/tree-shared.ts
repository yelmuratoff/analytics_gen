/** Shared style constants for tree sidebars (Events, Shared Params, Contexts) */

export const hoverAction = {
  opacity: 0, transition: 'opacity 0.1s', color: 'text.disabled',
  p: 0.5, flexShrink: 0,
  '&:hover': { color: '#DF4926', bgcolor: 'rgba(223,73,38,0.06)', opacity: 1 },
  '.MuiListItemButton-root:hover &': { opacity: 1 },
} as const;

export const hoverEdit = {
  opacity: 0, transition: 'opacity 0.1s', color: 'text.disabled',
  p: 0.3, flexShrink: 0,
  '&:hover': { color: '#DF4926', bgcolor: 'rgba(223,73,38,0.06)', opacity: 1 },
  '.MuiListItemButton-root:hover &': { opacity: 0.7 },
} as const;

export const hoverDelete = {
  opacity: 0, transition: 'opacity 0.15s', color: 'text.disabled',
  p: 0.5, flexShrink: 0,
  '&:hover': { color: '#D32F2F', bgcolor: 'rgba(211,47,47,0.06)', opacity: 1 },
  '.MuiListItemButton-root:hover &': { opacity: 1 },
} as const;

export const addItemButton = {
  py: 0.3,
  opacity: 0.7,
  borderTop: '1px dashed',
  borderColor: 'divider',
  borderRadius: 0,
  mx: 1,
  mt: 0.5,
  '&:hover': { opacity: 1, bgcolor: 'rgba(223,73,38,0.04)' },
} as const;

export const truncatedText = {
  minWidth: 0,
  '& .MuiListItemText-primary': { display: 'flex', alignItems: 'center', overflow: 'hidden' },
} as const;

export const truncatedName = {
  overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
} as const;

export const sidebarScroll = {
  '&::-webkit-scrollbar': { width: 5 },
  '&::-webkit-scrollbar-thumb': { bgcolor: 'text.disabled', opacity: 0.5, borderRadius: 3 },
} as const;
