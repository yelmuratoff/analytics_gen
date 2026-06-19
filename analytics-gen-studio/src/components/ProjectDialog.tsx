import { useState } from 'react';
import Dialog from '@mui/material/Dialog';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import DialogActions from '@mui/material/DialogActions';
import TextField from '@mui/material/TextField';
import Button from '@mui/material/Button';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import IconButton from '@mui/material/IconButton';
import Tooltip from '@mui/material/Tooltip';
import FormControlLabel from '@mui/material/FormControlLabel';
import Switch from '@mui/material/Switch';
import ContentCopyRounded from '@mui/icons-material/ContentCopyRounded';
import CheckRounded from '@mui/icons-material/CheckRounded';
import { useStore } from '../state/store.ts';
import { copyToClipboard } from '../utils/export.ts';
import {
  computeRevision,
  deriveJsonName,
  getUniqueExportNames,
  setUniqueExportNames,
} from '../utils/project-meta.ts';

interface ProjectDialogProps {
  open: boolean;
  onClose: () => void;
}

function ReadOnlyField({ label, value }: { label: string; value: string }) {
  const [copied, setCopied] = useState(false);

  const handleCopy = () => {
    copyToClipboard(value).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    });
  };

  return (
    <Box>
      <Typography sx={{ fontSize: '0.72rem', fontWeight: 600, color: 'text.secondary', mb: 0.5 }}>
        {label}
      </Typography>
      <Box sx={{
        display: 'flex', alignItems: 'center', gap: 1,
        px: 1.25, py: 0.75, borderRadius: 2,
        bgcolor: 'action.hover', border: 1, borderColor: 'divider',
      }}>
        <Typography sx={{
          flex: 1, fontSize: '0.8rem', fontFamily: '"JetBrains Mono", monospace',
          color: 'text.primary', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
        }}>
          {value}
        </Typography>
        <Tooltip title={copied ? 'Copied' : 'Copy'} arrow>
          <IconButton size="small" onClick={handleCopy} sx={{ color: 'text.secondary' }}>
            {copied ? <CheckRounded sx={{ fontSize: 16, color: 'success.main' }} /> : <ContentCopyRounded sx={{ fontSize: 16 }} />}
          </IconButton>
        </Tooltip>
      </Box>
    </Box>
  );
}

export default function ProjectDialog({ open, onClose }: ProjectDialogProps) {
  const projectId = useStore((s) => s.projectId);
  const projectName = useStore((s) => s.projectName);
  const setProjectName = useStore((s) => s.setProjectName);
  const [unique, setUnique] = useState(getUniqueExportNames);

  // Revision reflects the current content; recomputed each render while open.
  const s = useStore.getState();
  const revision = open
    ? computeRevision({
        config: s.config,
        eventFiles: s.eventFiles,
        sharedParamFiles: s.sharedParamFiles,
        contextFiles: s.contextFiles,
      })
    : '';

  const handleToggleUnique = (value: boolean) => {
    setUnique(value);
    setUniqueExportNames(value);
  };

  const exampleName = deriveJsonName(projectName, { unique, revision });

  return (
    <Dialog open={open} onClose={onClose} maxWidth="xs" fullWidth>
      <DialogTitle sx={{ fontWeight: 700, pb: 1 }}>Project</DialogTitle>
      <DialogContent>
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2.5, pt: 0.5 }}>
          <TextField
            label="Project name"
            value={projectName}
            onChange={(e) => setProjectName(e.target.value)}
            placeholder="Untitled project"
            fullWidth
            helperText="Used as the base name for exported files."
          />

          <ReadOnlyField label="PROJECT ID" value={projectId} />
          <ReadOnlyField label="REVISION (CONTENT HASH)" value={revision} />

          <Box>
            <FormControlLabel
              control={<Switch checked={unique} onChange={(e) => handleToggleUnique(e.target.checked)} />}
              label={<Typography sx={{ fontSize: '0.85rem' }}>Unique export file names</Typography>}
            />
            <Typography sx={{ fontSize: '0.75rem', color: 'text.secondary', ml: 0.25 }}>
              Appends the content hash, e.g. <Box component="span" sx={{ fontFamily: '"JetBrains Mono", monospace' }}>{exampleName}</Box> — handy for CI artifacts.
            </Typography>
          </Box>
        </Box>
      </DialogContent>
      <DialogActions sx={{ px: 3, pb: 2.5 }}>
        <Button onClick={onClose} variant="outlined" size="small">Close</Button>
      </DialogActions>
    </Dialog>
  );
}
