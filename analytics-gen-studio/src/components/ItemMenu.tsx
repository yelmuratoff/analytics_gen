import { useState } from 'react';
import IconButton from '@mui/material/IconButton';
import Menu from '@mui/material/Menu';
import MenuItem from '@mui/material/MenuItem';
import ListItemIcon from '@mui/material/ListItemIcon';
import ListItemText from '@mui/material/ListItemText';
import Divider from '@mui/material/Divider';
import MoreVertRounded from '@mui/icons-material/MoreVertRounded';

export interface ItemMenuAction {
  label: string;
  icon: React.ReactNode;
  onClick: () => void;
  danger?: boolean;
  dividerBefore?: boolean;
}

const menuBtnSx = {
  opacity: 0, transition: 'opacity 0.1s', color: 'text.disabled',
  p: 0.4, flexShrink: 0,
  '.MuiListItemButton-root:hover &, .MuiListItemButton-root:focus-within &': { opacity: 0.6 },
  '&:hover': { color: 'text.secondary', opacity: 1 },
  '&:focus-visible': { opacity: 1, outline: '2px solid', outlineColor: 'primary.main', outlineOffset: 1 },
} as const;

export default function ItemMenu({ actions }: { actions: ItemMenuAction[] }) {
  const [anchor, setAnchor] = useState<HTMLElement | null>(null);

  return (
    <>
      <IconButton
        size="small"
        onClick={(e) => { e.stopPropagation(); setAnchor(e.currentTarget); }}
        sx={{ ...menuBtnSx, ...(anchor && { opacity: 1, color: 'text.secondary' }) }}
      >
        <MoreVertRounded sx={{ fontSize: 16 }} />
      </IconButton>
      <Menu
        anchorEl={anchor}
        open={!!anchor}
        onClose={() => setAnchor(null)}
        onClick={(e) => e.stopPropagation()}
        slotProps={{ paper: { sx: { borderRadius: 2.5, minWidth: 160 } } }}
      >
        {actions.map((a, i) => [
          a.dividerBefore && <Divider key={`d${i}`} />,
          <MenuItem key={i} onClick={() => { a.onClick(); setAnchor(null); }}
            sx={{ fontSize: '0.82rem', py: 0.6, ...(a.danger && { color: 'error.main' }) }}>
            <ListItemIcon sx={{ minWidth: 28, ...(a.danger && { color: 'error.main' }) }}>
              {a.icon}
            </ListItemIcon>
            <ListItemText primary={a.label} primaryTypographyProps={{ fontSize: '0.82rem' }} />
          </MenuItem>,
        ])}
      </Menu>
    </>
  );
}
