import { createContext, useContext, useEffect, useState, useMemo } from 'react';
import CssBaseline from '@mui/material/CssBaseline';
import CircularProgress from '@mui/material/CircularProgress';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Fade from '@mui/material/Fade';
import { ThemeProvider, createTheme, alpha } from '@mui/material/styles';
import Layout from './components/Layout.tsx';
import { loadSchemas, type LoadedSchemas } from './schemas/loader.ts';
import { applySchemaConstants } from './schemas/constants.ts';
import { setSchemaDefaultConfig } from './state/store.ts';

// ── Color mode context ──

type ColorMode = 'light' | 'dark';

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

function getTheme(mode: ColorMode) {
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
    error: { main: '#D32F2F' },
    success: { main: isLight ? '#2E7D32' : '#4CAF50' },
    info: { main: '#DF4926' },
    action: {
      hover: isLight ? 'rgba(0,0,0,0.03)' : 'rgba(255,255,255,0.05)',
      selected: isLight ? 'rgba(0,0,0,0.06)' : 'rgba(255,255,255,0.1)',
    },
  } as const;

  return createTheme({
    palette,
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
          '@import': "url('https://fonts.googleapis.com/css2?family=DM+Sans:ital,opsz,wght@0,9..40,400;0,9..40,500;0,9..40,600;0,9..40,700;0,9..40,800&family=JetBrains+Mono:wght@400;500&display=swap')",
          body: { overflow: 'hidden', transition: 'background-color 0.2s ease, color 0.2s ease' },
          '*, *::before, *::after': {
            scrollbarWidth: 'thin',
            scrollbarColor: isLight ? 'rgba(0,0,0,0.12) transparent' : 'rgba(255,255,255,0.12) transparent',
          },
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
            '&:focus-visible': { outline: '2px solid #DF4926', outlineOffset: 2 },
          },
          contained: {
            backgroundColor: '#DF4926',
            '&:hover': { backgroundColor: '#C03A1C' },
          },
          outlined: {
            borderColor: palette.divider,
            color: palette.text.secondary,
            '&:hover': {
              borderColor: '#DF4926',
              color: '#DF4926',
              backgroundColor: alpha('#DF4926', 0.04),
            },
          },
        },
      },
      MuiIconButton: {
        styleOverrides: {
          root: { borderRadius: 8, transition: 'all 0.15s ease', '&:focus-visible': { outline: '2px solid #DF4926', outlineOffset: 2 } },
        },
      },
      MuiTab: {
        styleOverrides: {
          root: {
            textTransform: 'none',
            fontWeight: 600,
            fontSize: '0.86rem',
            minHeight: 44,
            '&:focus-visible': { outline: '2px solid #DF4926', outlineOffset: -2, borderRadius: 6 },
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
              backgroundColor: alpha('#DF4926', 0.06),
              '&:hover': { backgroundColor: alpha('#DF4926', 0.1) },
            },
            '&:hover': { backgroundColor: palette.action.hover },
            '&:focus-visible': { outline: '2px solid #DF4926', outlineOffset: -2 },
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
            '&:hover .MuiOutlinedInput-notchedOutline': { borderColor: isLight ? '#CCC' : '#555' },
            '&.Mui-focused .MuiOutlinedInput-notchedOutline': { borderColor: '#DF4926', borderWidth: 1.5 },
          },
        },
      },
      MuiInputLabel: {
        defaultProps: { size: 'small' as const },
        styleOverrides: {
          root: { fontSize: '0.88rem', '&.Mui-focused': { color: '#DF4926' } },
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
            '&.Mui-checked': { color: '#DF4926' },
          },
        },
      },
      MuiSwitch: {
        styleOverrides: {
          root: { padding: 7 },
          switchBase: {
            '&.Mui-checked': { color: '#DF4926' },
            '&.Mui-checked + .MuiSwitch-track': { backgroundColor: '#DF4926' },
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

export default function App() {
  const [mode, setMode] = useState<ColorMode>(() =>
    (localStorage.getItem('studio-theme') as ColorMode) || 'light',
  );
  const [schemas, setSchemas] = useState<LoadedSchemas | null>(null);
  const [error, setError] = useState<string | null>(null);

  const toggleColorMode = () => {
    setMode((prev) => {
      const next = prev === 'light' ? 'dark' : 'light';
      localStorage.setItem('studio-theme', next);
      return next;
    });
  };

  const theme = useMemo(() => getTheme(mode), [mode]);

  useEffect(() => {
    loadSchemas()
      .then((loaded) => {
        applySchemaConstants({
          ...loaded,
          defaultParamType: loaded.parameterTypes[0] ?? 'string',
          parameterTypes: loaded.parameterTypes,
          paramFieldNames: loaded.paramFieldNames,
          paramMutualExclusions: loaded.paramMutualExclusions,
          stringOnlyFields: loaded.stringOnlyFields,
          numericOnlyFields: loaded.numericOnlyFields,
          operationsField: loaded.operationsField,
        });
        setSchemaDefaultConfig(loaded.defaultConfig);
        setSchemas(loaded);
      })
      .catch((err) => setError(err.message));
  }, []);

  return (
    <ColorModeContext.Provider value={{ mode, toggleColorMode }}>
      <ThemeProvider theme={theme}>
        <CssBaseline />
        {error ? (
          <Box sx={{
            display: 'flex', justifyContent: 'center', alignItems: 'center',
            height: '100vh', flexDirection: 'column', gap: 2, bgcolor: 'background.default',
          }}>
            <Box sx={{
              p: 5, borderRadius: 3, bgcolor: 'background.paper', textAlign: 'center',
              border: 1, borderColor: 'divider',
            }}>
              <Typography sx={{ fontWeight: 700, fontSize: '1rem', color: 'error.main', mb: 1 }}>
                Failed to load schemas
              </Typography>
              <Typography variant="body2" color="text.secondary">{error}</Typography>
            </Box>
          </Box>
        ) : !schemas ? (
          <Box sx={{
            display: 'flex', justifyContent: 'center', alignItems: 'center',
            height: '100vh', flexDirection: 'column', gap: 3, bgcolor: 'background.default',
          }}>
            <Fade in timeout={600}>
              <Box sx={{ textAlign: 'center' }}>
                <CircularProgress size={32} thickness={4} sx={{ color: '#DF4926' }} />
                <Typography sx={{ mt: 2.5, fontWeight: 500, fontSize: '0.85rem', color: 'text.secondary' }}>
                  Loading schemas...
                </Typography>
              </Box>
            </Fade>
          </Box>
        ) : (
          <Fade in timeout={300}>
            <Box sx={{ height: '100vh' }}>
              <Layout schemas={schemas} />
            </Box>
          </Fade>
        )}
      </ThemeProvider>
    </ColorModeContext.Provider>
  );
}
