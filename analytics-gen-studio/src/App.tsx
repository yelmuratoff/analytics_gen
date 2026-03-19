import { useEffect, useState } from 'react';
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

const theme = createTheme({
  palette: {
    mode: 'light',
    primary: {
      main: '#DF4926',
      light: '#E8694D',
      dark: '#C03A1C',
      contrastText: '#ffffff',
    },
    secondary: { main: '#1A1A1A' },
    background: {
      default: '#F5F3F0',
      paper: '#FCFDF7',
    },
    text: {
      primary: '#1A1A1A',
      secondary: '#888',
    },
    divider: '#EEEBE8',
    error: { main: '#D32F2F' },
    success: { main: '#2E7D32' },
    info: { main: '#DF4926' },
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
    subtitle1: { fontFamily: '"DM Sans", sans-serif', fontWeight: 600, fontSize: '0.88rem' },
    subtitle2: { fontFamily: '"DM Sans", sans-serif', fontWeight: 600, fontSize: '0.78rem', color: '#888' },
    body1: { fontFamily: '"DM Sans", sans-serif', fontWeight: 400, fontSize: '0.875rem', lineHeight: 1.6 },
    body2: { fontFamily: '"DM Sans", sans-serif', fontWeight: 400, fontSize: '0.82rem', lineHeight: 1.6 },
    button: { fontFamily: '"DM Sans", sans-serif', fontWeight: 600, fontSize: '0.82rem' },
    caption: { fontFamily: '"DM Sans", sans-serif', fontWeight: 500, fontSize: '0.75rem', color: '#999' },
    overline: { fontFamily: '"DM Sans", sans-serif', fontWeight: 600, fontSize: '0.75rem', letterSpacing: '0.04em' },
  },
  shape: { borderRadius: 10 },
  components: {
    MuiCssBaseline: {
      styleOverrides: {
        '@import': "url('https://fonts.googleapis.com/css2?family=DM+Sans:ital,opsz,wght@0,9..40,400;0,9..40,500;0,9..40,600;0,9..40,700;0,9..40,800&family=JetBrains+Mono:wght@400;500&display=swap')",
        body: { overflow: 'hidden' },
      },
    },
    MuiButton: {
      styleOverrides: {
        root: {
          textTransform: 'none',
          fontWeight: 600,
          borderRadius: 8,
          boxShadow: 'none',
          fontSize: '0.82rem',
          '&:hover': { boxShadow: 'none' },
        },
        contained: {
          backgroundColor: '#DF4926',
          '&:hover': { backgroundColor: '#C03A1C' },
        },
        outlined: {
          borderColor: '#E0DCD8',
          color: '#555',
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
        root: { borderRadius: 8, transition: 'all 0.15s ease' },
      },
    },
    MuiTab: {
      styleOverrides: {
        root: {
          textTransform: 'none',
          fontWeight: 600,
          fontSize: '0.84rem',
          minHeight: 44,
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
          '&:hover': { backgroundColor: 'rgba(0,0,0,0.025)' },
        },
      },
    },
    MuiDialog: {
      styleOverrides: {
        paper: {
          borderRadius: 16,
          boxShadow: '0 8px 40px rgba(0,0,0,0.06)',
          border: '1px solid #EEEBE8',
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
          '& .MuiOutlinedInput-notchedOutline': { borderColor: '#E0DCD8' },
          '&:hover .MuiOutlinedInput-notchedOutline': { borderColor: '#CCC' },
          '&.Mui-focused .MuiOutlinedInput-notchedOutline': { borderColor: '#DF4926', borderWidth: 1.5 },
        },
      },
    },
    MuiInputLabel: {
      defaultProps: { size: 'small' as const },
      styleOverrides: {
        root: { fontSize: '0.85rem', '&.Mui-focused': { color: '#DF4926' } },
      },
    },
    MuiSelect: {
      defaultProps: { size: 'small' },
    },
    MuiCheckbox: {
      styleOverrides: {
        root: {
          color: '#D0CCC8',
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
        track: { borderRadius: 10, backgroundColor: '#D0CCC8' },
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
          fontSize: '0.72rem',
          fontWeight: 500,
          backgroundColor: '#333',
          padding: '6px 12px',
        },
        arrow: { color: '#333' },
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
          boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
          border: '1px solid #EEEBE8',
          borderRadius: 12,
        },
      },
    },
    MuiMenu: {
      styleOverrides: {
        paper: {
          boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
          border: '1px solid #EEEBE8',
          borderRadius: 12,
        },
      },
    },
    MuiAutocomplete: {
      styleOverrides: {
        paper: {
          boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
          border: '1px solid #EEEBE8',
          borderRadius: 12,
        },
      },
    },
  },
});

export default function App() {
  const [schemas, setSchemas] = useState<LoadedSchemas | null>(null);
  const [error, setError] = useState<string | null>(null);
  useEffect(() => {
    loadSchemas()
      .then((loaded) => {
        applySchemaConstants({
          ...loaded,
          defaultParamType: loaded.parameterTypes[0] ?? 'string',
        });
        setSchemaDefaultConfig(loaded.defaultConfig);
        setSchemas(loaded);
      })
      .catch((err) => setError(err.message));
  }, []);

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      {error ? (
        <Box sx={{
          display: 'flex', justifyContent: 'center', alignItems: 'center',
          height: '100vh', flexDirection: 'column', gap: 2, bgcolor: 'background.default',
        }}>
          <Box sx={{
            p: 5, borderRadius: 3, bgcolor: '#FCFDF7', textAlign: 'center',
            border: '1px solid #EEEBE8',
          }}>
            <Typography sx={{ fontWeight: 700, fontSize: '1rem', color: '#D32F2F', mb: 1 }}>
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
              <Typography sx={{ mt: 2.5, fontWeight: 500, fontSize: '0.82rem', color: '#999' }}>
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
  );
}
