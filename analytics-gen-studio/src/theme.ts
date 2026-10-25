import { createContext, useContext } from 'react';
import { createTheme, alpha } from '@mui/material/styles';

// ── Color mode context ──

export type ColorMode = 'light' | 'dark';

interface ColorModeContextType {
  mode: ColorMode;
  toggleColorMode: () => void;
}

export const ColorModeContext = createContext<ColorModeContextType>({
  mode: 'light',
  toggleColorMode: () => {},
});

export function useColorMode() {
  return useContext(ColorModeContext);
}

// ── Theme factory ──

export function getTheme(mode: ColorMode) {
  const isLight = mode === 'light';

  const palette = {
    mode,
    primary: { main: '#DF4926', light: '#E8694D', dark: '#C03A1C', contrastText: '#ffffff' },
    secondary: { main: isLight ? '#1A1A1A' : '#E0E0E0' },
    background: {
      default: isLight ? '#F5F3F0' : '#121212',
      paper: isLight ? '#FCFDF7' : '#1E1E1E',
    },
    text: {
      primary: isLight ? '#1A1A1A' : '#E0E0E0',
      secondary: isLight ? '#888' : '#aaa',
      disabled: isLight ? '#bbb' : '#666',
    },
    divider: isLight ? '#EEEBE8' : '#333',
    error: { main: '#D32F2F', dark: '#B71C1C' },
    success: { main: isLight ? '#2E7D32' : '#4CAF50' },
    info: { main: '#DF4926' },
    action: {
      hover: isLight ? 'rgba(0,0,0,0.03)' : 'rgba(255,255,255,0.05)',
      selected: isLight ? 'rgba(0,0,0,0.06)' : 'rgba(255,255,255,0.1)',
    },
    brand: {
      events: '#E8A84E',
      shared: '#22A06B',
      contexts: '#6366F1',
      fileIcon: '#8B9DAF',
    },
    yaml: {
      bg: '#1E1E1E',
      key: '#DF4926',
      comment: '#5C5C5C',
      text: '#D4D4D4',
      boolean: '#E8A84E',
      number: '#B8D97A',
      string: '#B8D97A',
      null: '#7C8CFF',
      muted: '#B0B0B0',
      lineNumber: 'rgba(255,255,255,0.15)',
      border: 'rgba(255,255,255,0.06)',
      errorBadge: '#FF8A80',
    },
  } as const;

  return createTheme({
    palette,
    breakpoints: {
      values: { xs: 0, sm: 600, md: 768, lg: 900, xl: 1024 },
    },
    typography: {
      fontFamily: '"DM Sans", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
      fontSize: 13,
      h1: { fontFamily: '"DM Sans", sans-serif', fontWeight: 700, fontSize: '2rem', letterSpacing: '-0.02em' },
      h2: { fontFamily: '"DM Sans", sans-serif', fontWeight: 700, fontSize: '1.6rem', letterSpacing: '-0.02em' },
      h3: { fontFamily: '"DM Sans", sans-serif', fontWeight: 700, fontSize: '1.3rem', letterSpacing: '-0.01em' },
      h4: { fontFamily: '"DM Sans", sans-serif', fontWeight: 700, fontSize: '1.15rem', letterSpacing: '-0.01em' },
      h5: { fontFamily: '"DM Sans", sans-serif', fontWeight: 700, fontSize: '1.05rem' },
      h6: { fontFamily: '"DM Sans", sans-serif', fontWeight: 700, fontSize: '0.95rem' },
      subtitle1: { fontFamily: '"DM Sans", sans-serif', fontWeight: 600, fontSize: '0.9rem' },
      subtitle2: { fontFamily: '"DM Sans", sans-serif', fontWeight: 600, fontSize: '0.82rem', color: palette.text.secondary },
      body1: { fontFamily: '"DM Sans", sans-serif', fontWeight: 400, fontSize: '0.9rem', lineHeight: 1.6 },
      body2: { fontFamily: '"DM Sans", sans-serif', fontWeight: 400, fontSize: '0.85rem', lineHeight: 1.6 },
      button: { fontFamily: '"DM Sans", sans-serif', fontWeight: 600, fontSize: '0.85rem' },
      caption: { fontFamily: '"DM Sans", sans-serif', fontWeight: 500, fontSize: '0.75rem', color: palette.text.secondary },
      overline: { fontFamily: '"DM Sans", sans-serif', fontWeight: 600, fontSize: '0.75rem', letterSpacing: '0.04em' },
    },
    shape: { borderRadius: 8 },
    components: {
      MuiCssBaseline: {
        styleOverrides: {
          body: { overflow: 'hidden', transition: 'background-color 0.2s ease, color 0.2s ease' },
          '*, *::before, *::after': {
            scrollbarWidth: 'thin',
            scrollbarColor: isLight ? 'rgba(0,0,0,0.18) transparent' : 'rgba(255,255,255,0.15) transparent',
          },
          '@media (prefers-reduced-motion: reduce)': {
            '*, *::before, *::after': {
              animationDuration: '0.01ms !important',
              animationIterationCount: '1 !important',
              transitionDuration: '0.01ms !important',
              scrollBehavior: 'auto !important',
            },
          },
        },
      },
      MuiButtonBase: {
        defaultProps: { disableRipple: true },
        styleOverrides: {
          root: { '&:active': { transform: 'scale(0.97)' } },
        },
      },
      MuiButton: {
        styleOverrides: {
          root: {
            textTransform: 'none',
            fontWeight: 600,
            borderRadius: 8,
            boxShadow: 'none',
            fontSize: '0.85rem',
            '&:hover': { boxShadow: 'none' },
            '&:focus-visible': { outline: `2px solid ${palette.primary.main}`, outlineOffset: 2 },
          },
          contained: {
            backgroundColor: palette.primary.main,
            '&:hover': { backgroundColor: palette.primary.dark },
          },
          outlined: {
            borderColor: palette.divider,
            color: palette.text.secondary,
            '&:hover': {
              borderColor: palette.primary.main,
              color: palette.primary.main,
              backgroundColor: alpha(palette.primary.main, 0.04),
            },
          },
        },
      },
      MuiIconButton: {
        styleOverrides: {
          root: { borderRadius: 8, transition: 'all 0.15s ease', '&:focus-visible': { outline: `2px solid ${palette.primary.main}`, outlineOffset: 2 } },
        },
      },
      MuiTab: {
        styleOverrides: {
          root: {
            textTransform: 'none',
            fontWeight: 600,
            fontSize: '0.86rem',
            minHeight: 44,
            '&:focus-visible': { outline: `2px solid ${palette.primary.main}`, outlineOffset: -2, borderRadius: 6 },
          },
        },
      },
      MuiListItemButton: {
        styleOverrides: {
          root: {
            borderRadius: 6,
            margin: '1px 4px',
            transition: 'all 0.1s ease',
            '&.Mui-selected': {
              backgroundColor: alpha(palette.primary.main, 0.06),
              '&:hover': { backgroundColor: alpha(palette.primary.main, 0.1) },
            },
            '&:hover': { backgroundColor: palette.action.hover },
            '&:focus-visible': { outline: `2px solid ${palette.primary.main}`, outlineOffset: -2 },
          },
        },
      },
      MuiDialog: {
        styleOverrides: {
          paper: {
            borderRadius: 16,
            boxShadow: isLight ? '0 8px 40px rgba(0,0,0,0.06)' : '0 8px 40px rgba(0,0,0,0.4)',
            border: `1px solid ${palette.divider}`,
            backgroundColor: palette.background.paper,
          },
        },
      },
      MuiTextField: {
        defaultProps: { size: 'small' },
      },
      MuiOutlinedInput: {
        defaultProps: { size: 'small' as const },
        styleOverrides: {
          root: {
            borderRadius: 10,
            '& .MuiOutlinedInput-notchedOutline': { borderColor: palette.divider },
            '&:hover .MuiOutlinedInput-notchedOutline': { borderColor: palette.text.disabled },
            '&.Mui-focused .MuiOutlinedInput-notchedOutline': { borderColor: palette.primary.main, borderWidth: 1.5 },
          },
        },
      },
      MuiInputLabel: {
        defaultProps: { size: 'small' as const },
        styleOverrides: {
          root: { fontSize: '0.88rem', '&.Mui-focused': { color: palette.primary.main } },
        },
      },
      MuiSelect: {
        defaultProps: { size: 'small' },
      },
      MuiCheckbox: {
        styleOverrides: {
          root: {
            color: isLight ? '#D0CCC8' : '#555',
            borderRadius: 4,
            '&.Mui-checked': { color: palette.primary.main },
          },
        },
      },
      MuiSwitch: {
        styleOverrides: {
          root: { padding: 7 },
          switchBase: {
            '&.Mui-checked': { color: palette.primary.main },
            '&.Mui-checked + .MuiSwitch-track': { backgroundColor: palette.primary.main },
          },
          track: { borderRadius: 10, backgroundColor: isLight ? '#D0CCC8' : '#555' },
          thumb: { boxShadow: 'none' },
        },
      },
      MuiChip: {
        styleOverrides: {
          root: { fontWeight: 600, borderRadius: 6 },
        },
      },
      MuiTooltip: {
        defaultProps: { enterDelay: 300, enterNextDelay: 100 },
        styleOverrides: {
          tooltip: {
            borderRadius: 8,
            fontSize: '0.75rem',
            fontWeight: 500,
            backgroundColor: isLight ? '#333' : '#555',
            padding: '6px 12px',
          },
          arrow: { color: isLight ? '#333' : '#555' },
        },
      },
      MuiPaper: {
        styleOverrides: {
          root: {
            backgroundImage: 'none',
            boxShadow: 'none',
          },
        },
      },
      MuiPopover: {
        styleOverrides: {
          paper: {
            boxShadow: isLight ? '0 4px 20px rgba(0,0,0,0.06)' : '0 4px 20px rgba(0,0,0,0.3)',
            border: `1px solid ${palette.divider}`,
            borderRadius: 12,
          },
        },
      },
      MuiMenu: {
        styleOverrides: {
          paper: {
            boxShadow: isLight ? '0 4px 20px rgba(0,0,0,0.06)' : '0 4px 20px rgba(0,0,0,0.3)',
            border: `1px solid ${palette.divider}`,
            borderRadius: 12,
          },
        },
      },
      MuiAutocomplete: {
        styleOverrides: {
          paper: {
            boxShadow: isLight ? '0 4px 20px rgba(0,0,0,0.06)' : '0 4px 20px rgba(0,0,0,0.3)',
            border: `1px solid ${palette.divider}`,
            borderRadius: 12,
          },
        },
      },
    },
  });
}
