import { useState, useMemo } from 'react';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Tabs from '@mui/material/Tabs';
import Tab from '@mui/material/Tab';
import IconButton from '@mui/material/IconButton';
import Tooltip from '@mui/material/Tooltip';
import ContentCopyRounded from '@mui/icons-material/ContentCopyRounded';
import FileDownloadRounded from '@mui/icons-material/FileDownloadRounded';
import CheckCircleRounded from '@mui/icons-material/CheckCircleRounded';
import ErrorOutlineRounded from '@mui/icons-material/ErrorOutlineRounded';
import WrapTextRounded from '@mui/icons-material/WrapTextRounded';
import ArrowForwardRounded from '@mui/icons-material/ArrowForwardRounded';
import { useYamlPreview } from '../hooks/useYamlPreview.ts';
import { useValidation } from '../hooks/useValidation.ts';
import { useStore } from '../state/store.ts';
import { copyToClipboard, exportSingleFile } from '../utils/export.ts';
import type { SelectionPath } from '../types/index.ts';

function highlightYaml(content: string): React.ReactNode[] {
  return content.split('\n').map((line, i) => {
    const parts: React.ReactNode[] = [];
    if (line.trimStart().startsWith('#')) {
      parts.push(<span key={i} style={{ color: '#5C5C5C' }}>{line}</span>);
    } else {
      const match = line.match(/^(\s*)([\w_.-]+)(:)(.*)/);
      if (match) {
        const [, indent, key, colon, rest] = match;
        parts.push(<span key={`${i}i`}>{indent}</span>);
        parts.push(<span key={`${i}k`} style={{ color: '#DF4926' }}>{key}</span>);
        parts.push(<span key={`${i}c`} style={{ color: '#5C5C5C' }}>{colon}</span>);
        const val = rest.trim();
        if (!val) {
          parts.push(<span key={`${i}v`}>{rest}</span>);
        } else if (val === 'true' || val === 'false') {
          parts.push(<span key={`${i}v`} style={{ color: '#E8A84E' }}> {val}</span>);
        } else if (/^-?\d+(\.\d+)?$/.test(val)) {
          parts.push(<span key={`${i}v`} style={{ color: '#B8D97A' }}> {val}</span>);
        } else if (val.startsWith('"') || val.startsWith("'")) {
          parts.push(<span key={`${i}v`} style={{ color: '#B8D97A' }}> {val}</span>);
        } else {
          parts.push(<span key={`${i}v`} style={{ color: '#D4D4D4' }}> {val}</span>);
        }
      } else if (line.trimStart().startsWith('- ')) {
        const m2 = line.match(/^(\s*)(- )(.*)/);
        if (m2) {
          const [, indent, dash, val] = m2;
          parts.push(<span key={`${i}i`}>{indent}</span>);
          parts.push(<span key={`${i}d`} style={{ color: '#5C5C5C' }}>{dash}</span>);
          parts.push(<span key={`${i}v`} style={{ color: '#D4D4D4' }}>{val}</span>);
        } else {
          parts.push(<span key={i} style={{ color: '#D4D4D4' }}>{line}</span>);
        }
      } else {
        parts.push(<span key={i} style={{ color: '#D4D4D4' }}>{line}</span>);
      }
    }
    return <div key={i}>{parts.length > 0 ? parts : ' '}</div>;
  });
}

export default function YamlPreview() {
  const files = useYamlPreview();
  const activeTab = useStore((s) => s.activeTab);
  const setActiveTab = useStore((s) => s.setActiveTab);
  const setSelectedPath = useStore((s) => s.setSelectedPath);
  const errors = useValidation();
  const tabErrors = errors.filter((e) => e.tab === activeTab);
  const [activeFileIndex, setActiveFileIndex] = useState(0);
  const [copied, setCopied] = useState(false);
  const [wordWrap, setWordWrap] = useState(false);

  const safeIndex = Math.min(activeFileIndex, Math.max(0, files.length - 1));
  const currentFile = files[safeIndex];

  const highlighted = useMemo(
    () => currentFile ? highlightYaml(currentFile.content) : [],
    [currentFile],
  );
  const lineCount = currentFile ? currentFile.content.split('\n').length : 0;

  if (!currentFile) {
    return (
      <Box sx={{
        display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
        height: '100%', gap: 1,
      }}>
        <Typography sx={{ color: '#777', fontSize: '0.85rem', fontWeight: 600 }}>
          No output yet
        </Typography>
        <Typography sx={{ color: '#555', fontSize: '0.78rem' }}>
          Add events or parameters to see generated YAML
        </Typography>
      </Box>
    );
  }

  const handleCopy = async () => {
    await copyToClipboard(currentFile.content);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const previewBtn = { color: '#5C5C5C', '&:hover': { color: '#D4D4D4', bgcolor: 'rgba(255,255,255,0.06)' } };

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
            color: '#5C5C5C', fontFamily: '"JetBrains Mono", monospace',
            fontWeight: 500,
            '&.Mui-selected': { color: '#D4D4D4' },
          },
          '& .MuiTabs-indicator': { height: 2, bgcolor: '#DF4926' },
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
          color: '#B0B0B0', fontFamily: '"JetBrains Mono", monospace',
        }}>
          {currentFile.fileName}
        </Typography>
        {tabErrors.length === 0 && (
          <CheckCircleRounded sx={{ fontSize: 14, color: '#4CAF50', mr: 0.5 }} />
        )}
        <Typography sx={{ fontSize: '0.78rem', color: '#777', mr: 1.5 }}>
          {lineCount}L
        </Typography>
        <Tooltip title={wordWrap ? 'No wrap' : 'Wrap lines'} arrow>
          <IconButton size="small" onClick={() => setWordWrap(!wordWrap)} sx={{
            ...previewBtn,
            ...(wordWrap && { color: '#DF4926', bgcolor: 'rgba(223,73,38,0.1)' }),
          }}>
            <WrapTextRounded sx={{ fontSize: 16 }} />
          </IconButton>
        </Tooltip>
        <Tooltip title={copied ? 'Copied!' : 'Copy'} arrow>
          <IconButton size="small" onClick={handleCopy} sx={previewBtn}>
            {copied ? <CheckCircleRounded sx={{ fontSize: 16, color: '#4CAF50' }} /> : <ContentCopyRounded sx={{ fontSize: 16 }} />}
          </IconButton>
        </Tooltip>
        <Tooltip title="Download" arrow>
          <IconButton size="small" onClick={() => exportSingleFile(currentFile.content, currentFile.fileName)} sx={previewBtn}>
            <FileDownloadRounded sx={{ fontSize: 16 }} />
          </IconButton>
        </Tooltip>
      </Box>

      <Box sx={{
        flex: 1, overflow: 'auto',
        fontFamily: '"JetBrains Mono", monospace',
        fontSize: '0.78rem', lineHeight: 1.75,
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
              {Array.from({ length: lineCount }, (_, i) => <div key={i}>{i + 1}</div>)}
            </Box>
          )}
          <Box component="code" sx={{
            flex: 1, whiteSpace: wordWrap ? 'pre-wrap' : 'pre', wordBreak: wordWrap ? 'break-all' : 'normal', pl: 2.5, pr: 2,
            '& > div:hover': { bgcolor: 'rgba(255,255,255,0.04)', borderRadius: 0.5 },
          }}>
            {highlighted}
          </Box>
        </Box>
      </Box>

      {/* Validation errors */}
      {tabErrors.length > 0 && (
        <Box role="status" aria-live="polite" aria-label={`${tabErrors.length} validation error${tabErrors.length > 1 ? 's' : ''}`} sx={{
          borderTop: '1px solid rgba(255,255,255,0.08)',
          maxHeight: 160, overflow: 'auto',
          px: 2, py: 1.5,
          bgcolor: 'rgba(211,47,47,0.08)',
          scrollbarColor: 'rgba(255,255,255,0.08) transparent',
          '&::-webkit-scrollbar': { width: 4 },
          '&::-webkit-scrollbar-thumb': { bgcolor: 'rgba(255,255,255,0.08)', borderRadius: 3 },
        }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.75, mb: 1 }}>
            <ErrorOutlineRounded sx={{ fontSize: 16, color: '#FF8A80' }} />
            <Typography sx={{ fontSize: '0.82rem', color: '#FF8A80', fontWeight: 700 }}>
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
                fontSize: '0.78rem', color: '#EEEEEE', lineHeight: 1.7,
                fontFamily: '"JetBrains Mono", monospace',
                pl: 3, py: 0.4, borderRadius: 0.5,
                ...(hasNav && {
                  cursor: 'pointer',
                  textDecoration: 'underline',
                  textDecorationColor: 'rgba(255,138,128,0.3)',
                  textUnderlineOffset: '2px',
                  '&:hover': { bgcolor: 'rgba(223,73,38,0.12)', textDecorationColor: '#FF8A80' },
                }),
              }}>
                {hasNav && <ArrowForwardRounded sx={{ fontSize: 12, color: '#FF8A80', flexShrink: 0 }} />}
                {err.message}
              </Box>
            );
          })}
        </Box>
      )}
    </Box>
  );
}
