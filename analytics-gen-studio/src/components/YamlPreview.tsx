import { useState, useMemo, useEffect } from 'react';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Tabs from '@mui/material/Tabs';
import Tab from '@mui/material/Tab';
import IconButton from '@mui/material/IconButton';
import Tooltip from '@mui/material/Tooltip';
import { useTheme } from '@mui/material/styles';
import ContentCopyRounded from '@mui/icons-material/ContentCopyRounded';
import FileDownloadRounded from '@mui/icons-material/FileDownloadRounded';
import CheckCircleRounded from '@mui/icons-material/CheckCircleRounded';
import ErrorOutlineRounded from '@mui/icons-material/ErrorOutlineRounded';
import WrapTextRounded from '@mui/icons-material/WrapTextRounded';
import ArrowForwardRounded from '@mui/icons-material/ArrowForwardRounded';
import CodeRounded from '@mui/icons-material/CodeRounded';
import { useYamlPreview } from '../hooks/useYamlPreview.ts';
import { useValidation } from '../hooks/useValidation.ts';
import { useStore } from '../state/store.ts';
import { copyToClipboard, exportSingleFile } from '../utils/export.ts';
import EmptyState from './EmptyState.tsx';
import type { SelectionPath, ValidationError } from '../types/index.ts';

function escapeHtml(s: string): string {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

function buildErrorLineSet(content: string, errors: ValidationError[]): Set<number> {
  if (errors.length === 0) return new Set();
  const lines = content.split('\n');
  const errorLines = new Set<number>();

  // Build lookup structures from errors
  const errorEventNames = new Set<string>();
  const errorParamNames = new Set<string>();
  const errorFields = new Set<string>();
  // Map: eventName → set of field names that have errors
  const eventFieldErrors = new Map<string, Set<string>>();

  for (const err of errors) {
    if (err.event) errorEventNames.add(err.event);
    if (err.parameter) errorParamNames.add(err.parameter);
    if (err.contextProperty) errorParamNames.add(err.contextProperty);
    // Extract field name from message like "event_name cannot contain..."
    const fieldMatch = err.message.match(/^(\w+)\s/);
    if (fieldMatch && err.event) {
      errorFields.add(fieldMatch[1]);
      if (!eventFieldErrors.has(err.event)) eventFieldErrors.set(err.event, new Set());
      eventFieldErrors.get(err.event)!.add(fieldMatch[1]);
    }
  }

  // Track YAML context by indentation — generated YAML uses 2-space indent:
  // domain:           (0)
  //   event:          (2)
  //     field: val    (4)
  //     parameters:   (4)
  //       param: type (6)
  let currentDomain = '';
  let currentEvent = '';

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const match = line.match(/^(\s*)([\w_.-]+)(:)(.*)/);
    if (!match) continue;
    const [, indent, key] = match;
    const depth = indent.length;

    // Track context
    if (depth === 0) { currentDomain = key; currentEvent = ''; }
    if (depth === 2) { currentEvent = key; }

    // Event name line (indent 2)
    if (depth === 2 && errorEventNames.has(key)) {
      errorLines.add(i);
    }
    // Event field line (indent 4) — e.g. event_name within an error event
    if (depth === 4 && currentEvent && eventFieldErrors.get(currentEvent)?.has(key)) {
      errorLines.add(i);
    }
    // Parameter name that has errors (indent 6 for events, indent 2 for shared/contexts)
    if (errorParamNames.has(key)) {
      errorLines.add(i);
    }
  }

  return errorLines;
}

interface YamlColors {
  key: string; comment: string; text: string; boolean: string;
  number: string; string: string; null: string; errorBg: string;
}

function highlightYamlToHtml(content: string, colors: YamlColors, errorLines?: Set<number>): string {
  return content.split('\n').map((line, lineIndex) => {
    const hasError = errorLines?.has(lineIndex);
    const errorBg = hasError ? ` style="background:${colors.errorBg};border-radius:2px"` : '';
    if (line.trimStart().startsWith('#')) {
      return `<div${errorBg}><span style="color:${colors.comment}">${escapeHtml(line)}</span></div>`;
    }
    const match = line.match(/^(\s*)([\w_.-]+)(:)(.*)/);
    if (match) {
      const [, indent, key, colon, rest] = match;
      const val = rest.trim();
      let valHtml: string;
      if (!val) {
        valHtml = escapeHtml(rest);
      } else if (val === 'null' || val === '~') {
        valHtml = `<span style="color:${colors.null}"> ${escapeHtml(val)}</span>`;
      } else if (val === 'true' || val === 'false') {
        valHtml = `<span style="color:${colors.boolean}"> ${escapeHtml(val)}</span>`;
      } else if (/^-?\d+(\.\d+)?$/.test(val)) {
        valHtml = `<span style="color:${colors.number}"> ${escapeHtml(val)}</span>`;
      } else if (val.startsWith('"') || val.startsWith("'")) {
        valHtml = `<span style="color:${colors.string}"> ${escapeHtml(val)}</span>`;
      } else {
        valHtml = `<span style="color:${colors.text}"> ${escapeHtml(val)}</span>`;
      }
      return `<div${errorBg}>${escapeHtml(indent)}<span style="color:${colors.key}">${escapeHtml(key)}</span><span style="color:${colors.comment}">${colon}</span>${valHtml}</div>`;
    }
    const m2 = line.match(/^(\s*)(- )(.*)/);
    if (m2) {
      const [, indent, dash, val] = m2;
      return `<div${errorBg}>${escapeHtml(indent)}<span style="color:${colors.comment}">${escapeHtml(dash)}</span><span style="color:${colors.text}">${escapeHtml(val)}</span></div>`;
    }
    return `<div${errorBg}><span style="color:${colors.text}">${escapeHtml(line) || ' '}</span></div>`;
  }).join('');
}

const previewBtnSx = { color: 'yaml.comment', '&:hover': { color: 'yaml.text', bgcolor: 'yaml.border' } } as const;

export default function YamlPreview() {
  const files = useYamlPreview();
  const activeTab = useStore((s) => s.activeTab);
  const setActiveTab = useStore((s) => s.setActiveTab);
  const setSelectedPath = useStore((s) => s.setSelectedPath);
  const errors = useValidation();
  const tabErrors = errors.filter((e) => e.tab === activeTab);
  const selectedPath = useStore((s) => s.selectedPath);
  const [activeFileIndex, setActiveFileIndex] = useState(0);
  const [copied, setCopied] = useState(false);
  const [wordWrap, setWordWrap] = useState(false);

  // Sync YAML preview file tab with selected item in tree
  useEffect(() => {
    if (selectedPath && selectedPath.tab === activeTab && selectedPath.fileIndex !== undefined && selectedPath.fileIndex < files.length) {
      setActiveFileIndex(selectedPath.fileIndex);
    }
  }, [selectedPath, activeTab, files.length]);

  // Clamp index when file list changes (e.g. tab switch)
  useEffect(() => {
    if (activeFileIndex >= files.length) setActiveFileIndex(0);
  }, [files.length, activeFileIndex]);

  const safeIndex = Math.min(activeFileIndex, Math.max(0, files.length - 1));
  const currentFile = files[safeIndex];

  // Filter errors relevant to current file
  const currentFileErrors = useMemo(() => {
    if (!currentFile) return [];
    return tabErrors.filter((e) => {
      if (activeTab === 'config') return true; // config is single file
      return e.fileIndex === safeIndex;
    });
  }, [tabErrors, activeTab, safeIndex, currentFile]);

  const theme = useTheme();
  const yamlColors = useMemo((): YamlColors => ({
    key: theme.palette.yaml.key,
    comment: theme.palette.yaml.comment,
    text: theme.palette.yaml.text,
    boolean: theme.palette.yaml.boolean,
    number: theme.palette.yaml.number,
    string: theme.palette.yaml.string,
    null: theme.palette.yaml.null,
    errorBg: 'rgba(211,47,47,0.12)',
  }), [theme.palette.yaml]);

  const highlightedHtml = useMemo(
    () => {
      if (!currentFile) return '';
      const errorLines = buildErrorLineSet(currentFile.content, currentFileErrors);
      return highlightYamlToHtml(currentFile.content, yamlColors, errorLines);
    },
    [currentFile, currentFileErrors, yamlColors],
  );
  const lineCount = currentFile ? currentFile.content.split('\n').length : 0;
  const lineNumbers = useMemo(
    () => Array.from({ length: lineCount }, (_, i) => <div key={i}>{i + 1}</div>),
    [lineCount],
  );

  if (!currentFile) {
    return (
      <EmptyState
        icon={<CodeRounded sx={{ fontSize: 28, color: 'yaml.comment' }} />}
        title="YAML Preview"
        description="Add configuration, events, or parameters — generated YAML will appear here in real-time."
        accentColor="rgba(255,255,255,0.12)"
      />
    );
  }

  const handleCopy = async () => {
    await copyToClipboard(currentFile.content);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const previewBtn = previewBtnSx;

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      {/* Always show file tabs for consistency */}
      <Tabs
        value={safeIndex}
        onChange={(_, v) => setActiveFileIndex(v)}
        variant="scrollable"
        scrollButtons="auto"
        sx={{
          minHeight: 32,
          borderBottom: '1px solid rgba(255,255,255,0.06)',
          '& .MuiTab-root': {
            minHeight: 32, py: 0, fontSize: '0.78rem',
            color: 'yaml.comment', fontFamily: '"JetBrains Mono", monospace',
            fontWeight: 500,
            '&.Mui-selected': { color: 'yaml.text' },
          },
          '& .MuiTabs-indicator': { height: 2, bgcolor: 'primary.main' },
        }}
      >
        {files.map((f, i) => <Tab key={i} label={f.fileName} disableRipple />)}
      </Tabs>

      <Box sx={{
        display: 'flex', alignItems: 'center',
        px: 2, py: 0.75,
        borderBottom: '1px solid rgba(255,255,255,0.06)',
      }}>
        <Typography sx={{
          flex: 1, fontSize: '0.78rem', fontWeight: 600,
          color: 'yaml.muted', fontFamily: '"JetBrains Mono", monospace',
        }}>
          {currentFile.fileName}
        </Typography>
        {tabErrors.length === 0 ? (
          <CheckCircleRounded sx={{ fontSize: 14, color: 'success.main', mr: 0.5 }} />
        ) : (
          <Tooltip title={`${tabErrors.length} issue${tabErrors.length > 1 ? 's' : ''} — click to scroll`} arrow>
            <Box
              onClick={() => {
                const el = document.getElementById('yaml-error-panel');
                el?.scrollIntoView({ behavior: 'smooth' });
              }}
              sx={{
                display: 'inline-flex', alignItems: 'center', gap: 0.5,
                px: 1, py: 0.2, mr: 0.5, borderRadius: 1.5,
                bgcolor: (t: any) => `${t.palette.error.main}26`, cursor: 'pointer',
                '&:hover': { bgcolor: (t: any) => `${t.palette.error.main}40` },
              }}
            >
              <ErrorOutlineRounded sx={{ fontSize: 13, color: 'yaml.errorBadge' }} />
              <Typography sx={{ fontSize: '0.72rem', color: 'yaml.errorBadge', fontWeight: 700 }}>
                {tabErrors.length}
              </Typography>
            </Box>
          </Tooltip>
        )}
        <Typography sx={{ fontSize: '0.78rem', color: 'yaml.comment', mr: 1.5 }}>
          {lineCount}L
        </Typography>
        <Tooltip title={wordWrap ? 'No wrap' : 'Wrap lines'} arrow>
          <IconButton size="small" aria-label={wordWrap ? 'Disable word wrap' : 'Enable word wrap'} onClick={() => setWordWrap(!wordWrap)} sx={{
            ...previewBtn,
            ...(wordWrap && { color: 'primary.main', bgcolor: 'action.selected' }),
          }}>
            <WrapTextRounded sx={{ fontSize: 16 }} />
          </IconButton>
        </Tooltip>
        <Tooltip title={copied ? 'Copied!' : 'Copy'} arrow>
          <IconButton size="small" aria-label="Copy to clipboard" onClick={handleCopy} sx={previewBtn}>
            {copied ? <CheckCircleRounded sx={{ fontSize: 16, color: 'success.main' }} /> : <ContentCopyRounded sx={{ fontSize: 16 }} />}
          </IconButton>
        </Tooltip>
        <Tooltip title="Download" arrow>
          <IconButton size="small" aria-label="Download file" onClick={() => exportSingleFile(currentFile.content, currentFile.fileName)} sx={previewBtn}>
            <FileDownloadRounded sx={{ fontSize: 16 }} />
          </IconButton>
        </Tooltip>
      </Box>

      <Box sx={{
        flex: 1, overflow: 'auto',
        fontFamily: '"JetBrains Mono", monospace',
        fontSize: '0.78rem', lineHeight: 1.75,
        scrollbarWidth: 'thin' as const,
        scrollbarColor: 'rgba(255,255,255,0.08) transparent',
        '&::-webkit-scrollbar': { width: 5 },
        '&::-webkit-scrollbar-thumb': { bgcolor: 'rgba(255,255,255,0.08)', borderRadius: 3 },
      }}>
        <Box component="pre" sx={{ m: 0, display: 'flex', py: 1.5 }}>
          {!wordWrap && (
            <Box component="span" sx={{
              px: 2, borderRight: '1px solid rgba(255,255,255,0.04)',
              color: 'rgba(255,255,255,0.15)', userSelect: 'none',
              textAlign: 'right', minWidth: '3em', fontSize: '0.75rem',
            }}>
              {lineNumbers}
            </Box>
          )}
          <Box component="code" sx={{
            flex: 1, whiteSpace: wordWrap ? 'pre-wrap' : 'pre', wordBreak: wordWrap ? 'break-all' : 'normal', pl: 2.5, pr: 2,
            '& > div:hover': { bgcolor: 'rgba(255,255,255,0.04)', borderRadius: 0.5 },
          }} dangerouslySetInnerHTML={{ __html: highlightedHtml }} />
        </Box>
      </Box>

      {/* Validation errors */}
      {tabErrors.length > 0 && (
        <Box id="yaml-error-panel" role="status" aria-live="polite" aria-label={`${tabErrors.length} validation error${tabErrors.length > 1 ? 's' : ''}`} sx={{
          borderTop: '1px solid rgba(255,255,255,0.08)',
          maxHeight: 160, overflow: 'auto',
          px: 2, py: 1.5,
          bgcolor: (t: any) => `${t.palette.error.main}14`,
          scrollbarWidth: 'thin' as const,
          scrollbarColor: 'rgba(255,255,255,0.08) transparent',
          '&::-webkit-scrollbar': { width: 4 },
          '&::-webkit-scrollbar-thumb': { bgcolor: 'rgba(255,255,255,0.08)', borderRadius: 3 },
        }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.75, mb: 1 }}>
            <ErrorOutlineRounded sx={{ fontSize: 16, color: 'yaml.errorBadge' }} />
            <Typography sx={{ fontSize: '0.82rem', color: 'yaml.errorBadge', fontWeight: 700 }}>
              {tabErrors.length} issue{tabErrors.length > 1 ? 's' : ''}
            </Typography>
          </Box>
          {tabErrors.map((err, i) => {
            const hasNav = err.tab === 'config' || err.fileIndex !== undefined;
            const handleClick = hasNav ? () => {
              setActiveTab(err.tab);
              if (err.tab === 'config') {
                setSelectedPath(null);
              } else {
                const nav: SelectionPath = { tab: err.tab, fileIndex: err.fileIndex! };
                if (err.tab === 'events') {
                  if (err.domain) nav.domain = err.domain;
                  if (err.event) nav.event = err.event;
                  if (err.parameter) nav.parameter = err.parameter;
                } else if (err.tab === 'shared') {
                  if (err.parameter) nav.parameter = err.parameter;
                } else if (err.tab === 'contexts') {
                  if (err.contextProperty) nav.contextProperty = err.contextProperty;
                }
                setSelectedPath(nav);
              }
            } : undefined;
            return (
              <Box key={i} onClick={handleClick} sx={{
                display: 'flex', alignItems: 'center', gap: 0.75,
                fontSize: '0.78rem', color: 'yaml.text', lineHeight: 1.7,
                fontFamily: '"JetBrains Mono", monospace',
                pl: 3, py: 0.4, borderRadius: 0.5,
                ...(hasNav && {
                  cursor: 'pointer',
                  textDecoration: 'underline',
                  textDecorationColor: 'yaml.errorBadge',
                  textUnderlineOffset: '2px',
                  '&:hover': { bgcolor: (t: any) => `${t.palette.primary.main}1F`, textDecorationColor: 'yaml.errorBadge' },
                }),
              }}>
                {hasNav && <ArrowForwardRounded sx={{ fontSize: 12, color: 'yaml.errorBadge', flexShrink: 0 }} />}
                {err.message}
              </Box>
            );
          })}
        </Box>
      )}
    </Box>
  );
}
