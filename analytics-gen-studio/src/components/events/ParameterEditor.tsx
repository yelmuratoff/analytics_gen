import { useState } from 'react';
import Form from '@rjsf/mui';
import type { RJSFSchema } from '@rjsf/utils';
import type { IChangeEvent } from '@rjsf/core';
import validator from '@rjsf/validator-ajv8';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import FormControlLabel from '@mui/material/FormControlLabel';
import Switch from '@mui/material/Switch';
import Select from '@mui/material/Select';
import MenuItem from '@mui/material/MenuItem';
import FormControl from '@mui/material/FormControl';
import InputLabel from '@mui/material/InputLabel';
import { parameterEditorUiSchema } from '../../schemas/ui-schemas.ts';
import { useStore } from '../../state/store.ts';
import type { ParamDef } from '../../types/index.ts';

const TYPES = ['string', 'int', 'double', 'bool', 'num', 'dynamic', 'string?', 'int?', 'double?', 'bool?', 'num?', 'dynamic?'];

interface ParameterEditorProps {
  fileIndex: number;
  domain: string;
  eventName: string;
  paramName: string;
  parameterSchema: RJSFSchema;
}

export default function ParameterEditor({ fileIndex, domain, eventName, paramName, parameterSchema }: ParameterEditorProps) {
  const files = useStore((s) => s.eventFiles);
  const updateParameter = useStore((s) => s.updateParameter);
  const [advanced, setAdvanced] = useState(false);

  const file = files[fileIndex];
  if (!file) return null;
  const event = file.domains[domain]?.[eventName];
  if (!event) return null;
  const rawValue = event.parameters[paramName];

  // Shared ref
  if (rawValue === null) {
    return (
      <Box>
        <Box sx={{ mb: 3 }}>
          <Typography variant="h5">
            {paramName}
          </Typography>
          <Typography variant="caption">shared reference</Typography>
        </Box>
        <Box sx={{
          p: 2.5, borderRadius: 1.5, border: '2px dashed #E8E4E0',
          bgcolor: '#FAF7F4',
        }}>
          <Typography variant="subtitle1" sx={{ color: '#DF4926', mb: 0.5 }}>
            Shared Parameter
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Defined in Shared Parameters tab. Resolved at generation time.
          </Typography>
        </Box>
      </Box>
    );
  }

  const formData: ParamDef = typeof rawValue === 'string'
    ? { type: rawValue }
    : (rawValue ?? { type: 'string' });

  const header = (
    <Box sx={{ mb: 3, display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
      <Box>
        <Typography variant="h5">
          {paramName}
        </Typography>
        <Typography variant="caption">{eventName} / {domain}</Typography>
      </Box>
      <FormControlLabel
        control={<Switch checked={advanced} onChange={(_, v) => setAdvanced(v)} size="small"
          sx={{ '& .MuiSwitch-switchBase.Mui-checked': { color: '#DF4926' },
            '& .MuiSwitch-switchBase.Mui-checked + .MuiSwitch-track': { bgcolor: '#DF4926' } }}
        />}
        label={<Typography variant="caption" sx={{ fontWeight: 600 }}>Advanced</Typography>}
      />
    </Box>
  );

  if (!advanced) {
    return (
      <Box>
        {header}
        <FormControl fullWidth size="small">
          <InputLabel>Type</InputLabel>
          <Select
            value={formData.type ?? 'string'}
            label="Type"
            onChange={(e) => updateParameter(fileIndex, domain, eventName, paramName, e.target.value)}
          >
            {TYPES.map((t) => (
              <MenuItem key={t} value={t}>
                <Typography sx={{ fontFamily: '"JetBrains Mono", monospace', fontSize: '0.82rem' }}>{t}</Typography>
              </MenuItem>
            ))}
          </Select>
        </FormControl>
      </Box>
    );
  }

  const handleChange = (e: IChangeEvent) => {
    if (e.formData) updateParameter(fileIndex, domain, eventName, paramName, e.formData as ParamDef);
  };

  return (
    <Box>
      {header}
      <Form
        schema={parameterSchema}
        uiSchema={parameterEditorUiSchema}
        formData={formData}
        validator={validator}
        onChange={handleChange}
        liveValidate
        showErrorList={false}
      >
        <div />
      </Form>
    </Box>
  );
}
