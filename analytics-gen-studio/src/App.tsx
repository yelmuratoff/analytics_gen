import { Component, useEffect, useState, useMemo } from 'react';
import type { ErrorInfo, ReactNode } from 'react';
import CssBaseline from '@mui/material/CssBaseline';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import Fade from '@mui/material/Fade';
import Skeleton from '@mui/material/Skeleton';
import { ThemeProvider } from '@mui/material/styles';
import { ColorModeContext, getTheme, type ColorMode } from './theme.ts';
import Layout from './components/Layout.tsx';
import { loadSchemas, type LoadedSchemas } from './schemas/loader.ts';
import { applySchemaConstants } from './schemas/constants.ts';
import { setSchemaDefaultConfig } from './state/store.ts';
import { refreshValidation } from './hooks/useValidation.ts';

// ── Error Boundary ──

class ErrorBoundary extends Component<{ children: ReactNode }, { error: Error | null }> {
  state: { error: Error | null } = { error: null };

  static getDerivedStateFromError(error: Error) {
    return { error };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    console.error('Studio crashed:', error, info.componentStack);
  }

  render() {
    if (this.state.error) {
      const isDark = localStorage.getItem('studio-theme') === 'dark';
      return (
        <Box sx={{
          display: 'flex', justifyContent: 'center', alignItems: 'center',
          height: '100vh', flexDirection: 'column', gap: 2,
          bgcolor: isDark ? '#121212' : '#F5F3F0',
        }}>
          <Box sx={{
            p: 5, borderRadius: 3, textAlign: 'center',
            bgcolor: isDark ? '#1E1E1E' : '#FCFDF7',
            border: '1px solid', borderColor: isDark ? '#333' : '#EEEBE8',
            maxWidth: 420,
          }}>
            <Typography sx={{ fontWeight: 700, fontSize: '1rem', color: 'error.main', mb: 1 }}>
              Something went wrong
            </Typography>
            <Typography sx={{ fontSize: '0.85rem', color: 'text.secondary', mb: 2, fontFamily: '"JetBrains Mono", monospace', wordBreak: 'break-word' }}>
              {this.state.error.message}
            </Typography>
            <Box sx={{ display: 'flex', gap: 1, justifyContent: 'center' }}>
              <Button size="small" variant="outlined" onClick={() => {
                localStorage.removeItem('analytics-gen-studio');
                window.location.reload();
              }} sx={{ fontSize: '0.82rem' }}>
                Reset &amp; Reload
              </Button>
              <Button size="small" variant="contained" onClick={() => window.location.reload()}
                sx={{ fontSize: '0.82rem' }}>
                Reload
              </Button>
            </Box>
          </Box>
        </Box>
      );
    }
    return this.props.children;
  }
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
        });
        setSchemaDefaultConfig(loaded.defaultConfig);
        refreshValidation();
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
          <Fade in timeout={400}>
            <Box sx={{ height: '100vh', bgcolor: 'background.default', display: 'flex', flexDirection: 'column' }}>
              {/* Toolbar skeleton */}
              <Box sx={{ px: 3, py: 1.2, bgcolor: 'background.paper', borderBottom: 1, borderColor: 'divider', display: 'flex', alignItems: 'center', gap: 2 }}>
                <Skeleton variant="rounded" width={120} height={32} />
                <Skeleton variant="rounded" width={48} height={20} sx={{ borderRadius: 1.5 }} />
                <Box sx={{ flex: 1 }} />
                {[60, 60, 80].map((w, i) => <Skeleton key={i} variant="rounded" width={w} height={28} />)}
              </Box>
              {/* TabBar skeleton */}
              <Box sx={{ px: 2, py: 0.8, bgcolor: 'background.paper', borderBottom: 1, borderColor: 'divider', display: 'flex', gap: 1 }}>
                {[80, 70, 110, 80].map((w, i) => <Skeleton key={i} variant="rounded" width={w} height={32} />)}
              </Box>
              {/* Content skeleton */}
              <Box sx={{ flex: 1, display: 'flex', p: 2, gap: 0 }}>
                <Box sx={{ flex: '0 0 57%', bgcolor: 'background.paper', borderRadius: 1.5, border: 1, borderColor: 'divider', p: 3 }}>
                  <Skeleton variant="rounded" width={180} height={24} sx={{ mb: 1 }} />
                  <Skeleton variant="rounded" width={120} height={14} sx={{ mb: 3 }} />
                  {[1, 2, 3].map((i) => (
                    <Box key={i} sx={{ mb: 1.5, borderRadius: 2.5, border: 1, borderColor: 'divider', p: 2 }}>
                      <Skeleton variant="rounded" width={140} height={18} sx={{ mb: 1.5 }} />
                      <Skeleton variant="rounded" height={36} sx={{ mb: 1 }} />
                      <Skeleton variant="rounded" height={36} />
                    </Box>
                  ))}
                </Box>
                <Box sx={{ width: 12 }} />
                <Box sx={{ flex: 1, bgcolor: 'background.paper', borderRadius: 1.5, p: 2 }}>
                  <Skeleton variant="rounded" width={140} height={20} sx={{ mb: 2, bgcolor: 'rgba(255,255,255,0.06)' }} />
                  {Array.from({ length: 8 }, (_, i) => (
                    <Skeleton key={i} variant="rounded" height={14} sx={{ mb: 1, bgcolor: 'rgba(255,255,255,0.04)', width: `${50 + Math.random() * 40}%` }} />
                  ))}
                </Box>
              </Box>
            </Box>
          </Fade>
        ) : (
          <ErrorBoundary>
            <Fade in timeout={300}>
              <Box sx={{ height: '100vh' }}>
                <Layout schemas={schemas} />
              </Box>
            </Fade>
          </ErrorBoundary>
        )}
      </ThemeProvider>
    </ColorModeContext.Provider>
  );
}
