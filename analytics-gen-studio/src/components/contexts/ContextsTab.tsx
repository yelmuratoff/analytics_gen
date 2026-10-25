import { useState, useTransition } from 'react';
import Box from '@mui/material/Box';
import List from '@mui/material/List';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemText from '@mui/material/ListItemText';
import ListItemIcon from '@mui/material/ListItemIcon';
import IconButton from '@mui/material/IconButton';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import CircularProgress from '@mui/material/CircularProgress';
import Collapse from '@mui/material/Collapse';
import Dialog from '@mui/material/Dialog';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import DialogActions from '@mui/material/DialogActions';
import TextField from '@mui/material/TextField';
import InputAdornment from '@mui/material/InputAdornment';
import InsertDriveFileRounded from '@mui/icons-material/InsertDriveFileRounded';
import FolderRounded from '@mui/icons-material/FolderRounded';
import CircleRounded from '@mui/icons-material/CircleRounded';
import KeyboardArrowRightRounded from '@mui/icons-material/KeyboardArrowRightRounded';
import KeyboardArrowDownRounded from '@mui/icons-material/KeyboardArrowDownRounded';
import DeleteOutlineRounded from '@mui/icons-material/DeleteOutlineRounded';
import EditRounded from '@mui/icons-material/EditRounded';
import AddRounded from '@mui/icons-material/AddRounded';
import LayersRounded from '@mui/icons-material/LayersRounded';
import SearchRounded from '@mui/icons-material/SearchRounded';
import UnfoldMoreRounded from '@mui/icons-material/UnfoldMoreRounded';
import UnfoldLessRounded from '@mui/icons-material/UnfoldLessRounded';
import Tooltip from '@mui/material/Tooltip';
import { alpha } from '@mui/material/styles';
import type { RJSFSchema } from '@rjsf/utils';
import { useStore } from '../../state/store.ts';
import { SNAKE_CASE_PARAM, DEFAULT_PARAM_TYPE } from '../../schemas/constants.ts';
import { addItemButton, sidebarScroll, PAGE_SIZE } from '../../styles/tree-shared.ts';
import { useDebouncedSearch } from '../../hooks/useDebouncedSearch.ts';
import { useResizeHandle } from '../../hooks/useResizeHandle.ts';
import { useErrorKeys, useErrorMessages } from '../../hooks/useValidation.ts';
import { useInlineRename } from '../../hooks/useInlineRename.ts';
import { withYamlExtension } from '../../utils/file-names.ts';
import { newNameError } from '../../utils/validation.ts';
import InlineRenameField from '../InlineRenameField.tsx';
import ErrorDot from '../ErrorDot.tsx';
import ItemMenu from '../ItemMenu.tsx';
import AddItemDialog from '../AddItemDialog.tsx';
import ConfirmDialog from '../ConfirmDialog.tsx';
import EmptyState from '../EmptyState.tsx';
import ResizeHandle from '../ResizeHandle.tsx';
import ContextPropertyEditor from './ContextPropertyEditor.tsx';

function deriveContextName(fileName: string): string {
  return fileName.replace(/\.yaml$/, '').replace(/[^a-z0-9_]/g, '_').replace(/^[^a-z]/, '').replace(/_+/g, '_').replace(/_$/, '');
}

interface ContextsTabProps {
  parameterSchema: RJSFSchema;
  operations: string[];
}

export default function ContextsTab({ parameterSchema, operations }: ContextsTabProps) {
  const files = useStore((s) => s.contextFiles);
  const selectedPath = useStore((s) => s.selectedPath);
  const setSelectedPath = useStore((s) => s.setSelectedPath);
  const addContextFile = useStore((s) => s.addContextFile);
  const removeContextFile = useStore((s) => s.removeContextFile);
  const addContextProperty = useStore((s) => s.addContextProperty);
  const removeContextProperty = useStore((s) => s.removeContextProperty);
  const renameContextFile = useStore((s) => s.renameContextFile);
  const renameContextName = useStore((s) => s.renameContextName);
  const renameContextProperty = useStore((s) => s.renameContextProperty);
  const enforceSnakeParams = useStore((s) => !!s.config.naming?.enforce_snake_case_parameters);

  const errorKeys = useErrorKeys();
  const errorMessages = useErrorMessages();
  const { searchInput, search, isPending: isSearchPending, handleSearchChange } = useDebouncedSearch();
  const [isExpandPending, startTransition] = useTransition();
  const isPending = isSearchPending || isExpandPending;
  const [addFileOpen, setAddFileOpen] = useState(false);
  const [fileNameInput, setFileNameInput] = useState('');
  const [contextNameInput, setContextNameInput] = useState('');
  const rename = useInlineRename<{ type: 'file' | 'context' | 'prop'; fi: number; original: string }>({
    takenNames: (t) => {
      if (t.type === 'file') return files.map((f) => f.fileName);
      if (t.type === 'context') return files.map((f) => f.contextName);
      return Object.keys(files[t.fi].properties);
    },
    normalize: (t, name) => t.type === 'file' ? withYamlExtension(name) : name,
    apply: (t, name) => {
      if (t.type === 'file') renameContextFile(t.fi, name);
      else if (t.type === 'context') renameContextName(t.fi, name);
      else renameContextProperty(t.fi, t.original, name);
    },
  });
  const editing = rename.target;
  const [addPropOpen, setAddPropOpen] = useState<number | null>(null);
  const [collapsedFiles, setCollapsedFiles] = useState<Set<number>>(new Set());
  const [confirmDelete, setConfirmDelete] = useState<{ title: string; message: string; action: () => void } | null>(null);
  const [visibleLimits, setVisibleLimits] = useState<Record<number, number>>({});
  const { width: sidebarWidth, dragging, atLimit, containerRef: sidebarRef, handleMouseDown } = useResizeHandle({
    initialWidth: 240, storageKey: 'studio-sidebar-contexts',
  });

  const q = search.toLowerCase();

  const isFileExpanded = (i: number) => !collapsedFiles.has(i);
  const toggleExpand = (i: number) => {
    startTransition(() => {
      setCollapsedFiles((prev) => {
        const next = new Set(prev);
        if (next.has(i)) next.delete(i); else next.add(i);
        return next;
      });
    });
  };
  const allExpanded = files.length > 0 && collapsedFiles.size === 0;
  const expandAllFiles = () => startTransition(() => setCollapsedFiles(new Set()));
  const collapseAllFiles = () => startTransition(() => setCollapsedFiles(new Set(files.map((_, i) => i))));

  const isSel = (fi: number, p?: string) =>
    selectedPath?.tab === 'contexts' && selectedPath.fileIndex === fi && selectedPath.contextProperty === p;

  const [fileError, setFileError] = useState('');
  const [ctxError, setCtxError] = useState('');

  const handleAddFile = () => {
    const fn = fileNameInput.trim();
    const cn = contextNameInput.trim();
    const fileNameError = newNameError(fn && withYamlExtension(fn), { isFileName: true, existingNames: files.map((f) => f.fileName) });
    if (fileNameError) { setFileError(fileNameError); return; }
    const contextNameError = newNameError(cn, { namePattern: SNAKE_CASE_PARAM, existingNames: files.map((f) => f.contextName) });
    if (contextNameError) { setCtxError(contextNameError); return; }
    addContextFile(withYamlExtension(fn), cn);
    setFileNameInput(''); setContextNameInput('');
    setFileError(''); setCtxError('');
    setAddFileOpen(false);
  };

  const fileMatchesSearch = (fi: number) => {
    if (!q) return true;
    const file = files[fi];
    if (file.fileName.toLowerCase().includes(q)) return true;
    if (file.contextName.toLowerCase().includes(q)) return true;
    return Object.keys(file.properties).some((pn) => pn.toLowerCase().includes(q));
  };

  const startEditing = (type: 'file' | 'context' | 'prop', fi: number, original: string) => rename.start({ type, fi, original });

  const renderInlineEdit = (fontSize = '0.82rem', height = 24) => (
    <InlineRenameField
      value={rename.value} error={rename.error}
      onChange={rename.setValue} onCommit={rename.commit} onCancel={rename.cancel}
      fontSize={fontSize} height={height}
    />
  );

  return (
    <Box sx={{ display: 'flex', height: '100%', mx: -3, mt: -1 }}>
      <Box ref={sidebarRef} sx={{
        width: sidebarWidth, minWidth: 200, borderRight: 1, borderColor: 'divider', overflow: 'auto', flexShrink: 0,
        ...sidebarScroll,
      }}>
        <Box sx={{ p: 1.5, display: 'flex', flexDirection: 'column', gap: 1 }}>
          <Box sx={{ display: 'flex', gap: 0.5 }}>
            <Button startIcon={<AddRounded />} size="small" onClick={() => setAddFileOpen(true)}
              fullWidth variant="outlined" sx={{ fontSize: '0.82rem', py: 0.5 }}>
              Add Context
            </Button>
            {files.length > 0 && (
              <Tooltip title={allExpanded ? 'Collapse all' : 'Expand all'} arrow>
                <IconButton size="small" onClick={allExpanded ? collapseAllFiles : expandAllFiles} sx={{
                  color: 'text.secondary', flexShrink: 0,
                  '&:hover': { color: 'primary.main', bgcolor: 'action.hover' },
                }}>
                  {allExpanded ? <UnfoldLessRounded sx={{ fontSize: 18 }} /> : <UnfoldMoreRounded sx={{ fontSize: 18 }} />}
                </IconButton>
              </Tooltip>
            )}
          </Box>
          <TextField
              size="small"
              placeholder={files.length > 0 ? 'Search...' : 'Add a context to search'}
              disabled={files.length === 0}
              value={searchInput}
              onChange={(e) => handleSearchChange(e.target.value)}
              slotProps={{
                htmlInput: { 'aria-label': 'Search contexts' },
                input: {
                  startAdornment: (
                    <InputAdornment position="start">
                      <SearchRounded sx={{ fontSize: 16, color: 'text.disabled' }} />
                    </InputAdornment>
                  ),
                  sx: { fontSize: '0.78rem', py: 0, height: 32 },
                },
              }}
            />
        </Box>
        {files.length === 0 && (
          <Box sx={{ px: 2, py: 4, textAlign: 'center' }}>
            <Box sx={{
              width: 56, height: 56, borderRadius: '50%', mx: 'auto', mb: 1.5,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              bgcolor: (t: any) => `${t.palette.brand.contexts}0F`, border: '2px dashed', borderColor: 'brand.contexts',
            }}>
              <LayersRounded sx={{ fontSize: 28, color: 'brand.contexts' }} />
            </Box>
            <Typography sx={{ fontSize: '0.85rem', color: 'text.secondary', mb: 0.5, fontWeight: 600 }}>No contexts yet</Typography>
            <Typography sx={{ fontSize: '0.78rem', color: 'text.disabled', lineHeight: 1.5, px: 1, mb: 1.5 }}>
              Contexts track state across the app lifecycle with set/update operations.
            </Typography>
            <Box sx={{
              mx: 1, mb: 2, p: 1.5, borderRadius: 2, bgcolor: 'yaml.bg', textAlign: 'left',
              fontFamily: '"JetBrains Mono", monospace', fontSize: '0.7rem', lineHeight: 1.7, color: 'yaml.text',
            }}>
              <Box><Box component="span" sx={{ color: 'yaml.comment' }}># user_properties.yaml</Box></Box>
              <Box><Box component="span" sx={{ color: 'yaml.key' }}>user_id</Box><Box component="span" sx={{ color: 'yaml.comment' }}>:</Box></Box>
              <Box>  <Box component="span" sx={{ color: 'yaml.key' }}>type</Box><Box component="span" sx={{ color: 'yaml.comment' }}>:</Box><Box component="span" sx={{ color: 'yaml.text' }}> string</Box></Box>
              <Box>  <Box component="span" sx={{ color: 'yaml.key' }}>operations</Box><Box component="span" sx={{ color: 'yaml.comment' }}>:</Box><Box component="span" sx={{ color: 'yaml.text' }}> [set]</Box></Box>
            </Box>
            <Button size="small" variant="contained" onClick={() => setAddFileOpen(true)} sx={{ fontSize: '0.78rem' }}>
              Add your first context
            </Button>
          </Box>
        )}
        <Box sx={{ position: 'relative' }}>
          {isPending && (
            <Box sx={{ position: 'absolute', inset: 0, zIndex: 2, display: 'flex', justifyContent: 'center', pt: 4 }}>
              <CircularProgress size={20} sx={{ color: 'primary.main' }} />
            </Box>
          )}
        <List dense disablePadding sx={{ px: 0.5, pb: 1, ...(isPending && { opacity: 0.4, pointerEvents: 'none' }) }}>
          {files.map((file, fi) => {
            if (!fileMatchesSearch(fi)) return null;
            return (
              <Box key={fi}>
                <ListItemButton onClick={() => toggleExpand(fi)} dense sx={{ py: 0.4 }}>
                  {isFileExpanded(fi) ? <KeyboardArrowDownRounded sx={{ fontSize: 18, color: 'text.secondary' }} />
                    : <KeyboardArrowRightRounded sx={{ fontSize: 18, color: 'text.disabled' }} />}
                  <ListItemIcon sx={{ minWidth: 26, ml: 0.2 }}>
                    <InsertDriveFileRounded sx={{ fontSize: 17, color: 'brand.contexts' }} />
                  </ListItemIcon>
                  {editing?.type === 'file' && editing.fi === fi
                    ? renderInlineEdit('0.85rem', 26)
                    : (
                      <>
                        <ListItemText
                          primary={<><Box component="span" sx={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{file.fileName}</Box><Typography component="span" sx={{ fontSize: '0.78rem', color: 'text.disabled', ml: 0.5, flexShrink: 0 }}>{Object.keys(file.properties).length || ''}</Typography>{errorKeys.has(`contexts:${fi}`) && <ErrorDot messages={errorMessages.get(`contexts:${fi}`)} />}</>}
                          primaryTypographyProps={{ fontSize: '0.85rem', fontWeight: 600 }}
                          sx={{ minWidth: 0, '& .MuiListItemText-primary': { display: 'flex', alignItems: 'center', overflow: 'hidden' } }}
                        />
                        <ItemMenu actions={[
                          { label: 'Rename', icon: <EditRounded sx={{ fontSize: 16 }} />, onClick: () => startEditing('file', fi, file.fileName) },
                          { label: 'Delete', icon: <DeleteOutlineRounded sx={{ fontSize: 16 }} />, onClick: () => setConfirmDelete({ title: `Delete ${file.fileName}?`, message: 'All properties in this context will be removed.', action: () => removeContextFile(fi) }), danger: true, dividerBefore: true },
                        ]} />
                      </>
                    )}
                </ListItemButton>
                <Collapse in={isFileExpanded(fi) || !!q} timeout={150} unmountOnExit>
                  <List dense disablePadding>
                    <ListItemButton sx={{ pl: 5, py: 0.3 }} dense onClick={(e) => e.stopPropagation()}>
                      <ListItemIcon sx={{ minWidth: 20 }}>
                        <FolderRounded sx={{ fontSize: 16, color: 'primary.main' }} />
                      </ListItemIcon>
                      {editing?.type === 'context' && editing.fi === fi
                        ? renderInlineEdit('0.82rem', 22)
                        : (
                          <>
                            <ListItemText primary={file.contextName} primaryTypographyProps={{
                              fontSize: '0.82rem', fontWeight: 600, color: 'primary.main',
                            }} />
                            <ItemMenu actions={[
                              { label: 'Rename', icon: <EditRounded sx={{ fontSize: 16 }} />, onClick: () => startEditing('context', fi, file.contextName) },
                            ]} />
                          </>
                        )}
                    </ListItemButton>
                    {(() => {
                      const propKeys = Object.keys(file.properties).filter((pn) =>
                        !q || pn.toLowerCase().includes(q) || file.fileName.toLowerCase().includes(q) || file.contextName.toLowerCase().includes(q)
                      );
                      const limit = q ? propKeys.length : (visibleLimits[fi] ?? PAGE_SIZE);
                      const visible = propKeys.slice(0, limit);
                      const remaining = propKeys.length - limit;
                      return (
                        <>
                          {visible.map((pn) => {
                            const hasErr = errorKeys.has(`contexts:${fi}:${pn}`);
                            return (
                            <ListItemButton key={pn} sx={{
                              pl: 7, py: 0.4,
                              ...(isSel(fi, pn) && { bgcolor: (t: any) => alpha(t.palette.primary.main, 0.06) }),
                            }} onClick={() => setSelectedPath({ tab: 'contexts', fileIndex: fi, contextProperty: pn })}>
                              <ListItemIcon sx={{ minWidth: 18 }}>
                                <CircleRounded sx={{ fontSize: 6, color: hasErr ? 'error.main' : 'text.disabled' }} />
                              </ListItemIcon>
                              {editing?.type === 'prop' && editing.fi === fi && editing.original === pn
                                ? renderInlineEdit('0.78rem', 24)
                                : (
                                  <>
                                    <ListItemText primary={<Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}><span>{pn}</span>{hasErr && <ErrorDot messages={errorMessages.get(`contexts:${fi}:${pn}`)} ml={0} />}</Box>} primaryTypographyProps={{
                                      fontSize: '0.78rem', fontFamily: '"JetBrains Mono", monospace',
                                    }} />
                                    <ItemMenu actions={[
                                      { label: 'Rename', icon: <EditRounded sx={{ fontSize: 16 }} />, onClick: () => startEditing('prop', fi, pn) },
                                      { label: 'Delete', icon: <DeleteOutlineRounded sx={{ fontSize: 16 }} />, onClick: () => setConfirmDelete({ title: `Delete "${pn}"?`, message: `This will remove the property "${pn}" from context "${file.contextName}".`, action: () => removeContextProperty(fi, pn) }), danger: true, dividerBefore: true },
                                    ]} />
                                  </>
                                )}
                            </ListItemButton>
                            );
                          })}
                          {remaining > 0 && (
                            <ListItemButton sx={{ pl: 7, py: 0.5, justifyContent: 'center' }}
                              onClick={() => setVisibleLimits((prev) => ({ ...prev, [fi]: Math.min((prev[fi] ?? PAGE_SIZE) + PAGE_SIZE, propKeys.length) }))} dense>
                              <Typography sx={{ fontSize: '0.75rem', color: 'primary.main', fontWeight: 600 }}>
                                Show {remaining} more {remaining > 1 ? 'properties' : 'property'}...
                              </Typography>
                            </ListItemButton>
                          )}
                          {!q && (
                            <ListItemButton sx={{ pl: 7, ...addItemButton }} onClick={() => setAddPropOpen(fi)}>
                              <AddRounded sx={{ fontSize: 15, color: 'primary.main', mr: 0.5 }} />
                              <ListItemText primary="Add Property" primaryTypographyProps={{
                                fontSize: '0.78rem', color: 'primary.main', fontWeight: 600,
                              }} />
                            </ListItemButton>
                          )}
                        </>
                      );
                    })()}
                  </List>
                </Collapse>
              </Box>
            );
          })}
        </List>
        </Box>
        {q && files.length > 0 && files.every((_, fi) => !fileMatchesSearch(fi)) && (
          <Typography sx={{ px: 2, py: 3, textAlign: 'center', fontSize: '0.78rem', color: 'text.disabled' }}>
            No matches for "{searchInput}"
          </Typography>
        )}
      </Box>
      <ResizeHandle dragging={dragging} atLimit={atLimit} onMouseDown={handleMouseDown} />
      <Box sx={{ flex: 1, overflow: 'auto', p: 3 }}>
        {selectedPath?.tab === 'contexts' && selectedPath.contextProperty ? (
          <ContextPropertyEditor fileIndex={selectedPath.fileIndex} propName={selectedPath.contextProperty} parameterSchema={parameterSchema} operations={operations} />
        ) : (
          <EmptyState
            icon={<LayersRounded sx={{ fontSize: 28, color: 'brand.contexts' }} />}
            title="Select a property"
            description="Context properties track state across the app lifecycle. Select operations and configure type."
            accentColor="brand.contexts"
          />
        )}
      </Box>

      <Dialog open={addFileOpen} onClose={() => { setAddFileOpen(false); setFileError(''); setCtxError(''); setFileNameInput(''); setContextNameInput(''); }} maxWidth="xs" fullWidth>
        <DialogTitle sx={{ fontWeight: 700, pb: 0.5 }}>Add Context</DialogTitle>
        <DialogContent sx={{ pt: '12px !important' }}>
          <TextField autoFocus fullWidth size="small" margin="dense" label="File name"
            placeholder="user_properties.yaml" value={fileNameInput}
            error={!!fileError} helperText={fileError}
            onChange={(e) => {
              const fn = e.target.value;
              setFileNameInput(fn); setFileError('');
              if (!contextNameInput || contextNameInput === deriveContextName(fileNameInput)) {
                setContextNameInput(deriveContextName(fn));
                setCtxError('');
              }
            }} sx={{ mt: 1 }} />
          <TextField fullWidth size="small" margin="dense" label="Context name"
            placeholder="user_properties" value={contextNameInput}
            error={!!ctxError} helperText={ctxError}
            onChange={(e) => { setContextNameInput(e.target.value); setCtxError(''); }}
            onKeyDown={(e) => { if (e.key === 'Enter') handleAddFile(); }} />
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2.5 }}>
          <Button onClick={() => { setAddFileOpen(false); setFileError(''); setCtxError(''); setFileNameInput(''); setContextNameInput(''); }} variant="outlined" size="small">Cancel</Button>
          <Button onClick={handleAddFile} variant="contained" size="small"
            disabled={!fileNameInput.trim() || !contextNameInput.trim()}>Add</Button>
        </DialogActions>
      </Dialog>

      {addPropOpen !== null && (
        <AddItemDialog open title="Add Property" label="Name" placeholder="user_id"
          namePattern={enforceSnakeParams ? SNAKE_CASE_PARAM : undefined} existingNames={Object.keys(files[addPropOpen]?.properties ?? {})}
          onClose={() => setAddPropOpen(null)}
          onAdd={(n) => {
            addContextProperty(addPropOpen, n, { type: DEFAULT_PARAM_TYPE });
            setSelectedPath({ tab: 'contexts', fileIndex: addPropOpen, contextProperty: n });
            setAddPropOpen(null);
          }} />
      )}
      {confirmDelete && (
        <ConfirmDialog open title={confirmDelete.title} message={confirmDelete.message}
          onConfirm={() => { confirmDelete.action(); setConfirmDelete(null); }}
          onCancel={() => setConfirmDelete(null)} />
      )}
    </Box>
  );
}
