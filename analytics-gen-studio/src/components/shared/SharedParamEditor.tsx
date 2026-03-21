import { useState } from 'react';
import Form from '@rjsf/mui';
import type { RJSFSchema } from '@rjsf/utils';
import type { IChangeEvent } from '@rjsf/core';
import validator from '@rjsf/validator-ajv8';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import Select from '@mui/material/Select';
import MenuItem from '@mui/material/MenuItem';
import FormControl from '@mui/material/FormControl';
import InputLabel from '@mui/material/InputLabel';
import Collapse from '@mui/material/Collapse';
import TuneRounded from '@mui/icons-material/TuneRounded';
import KeyboardArrowDownRounded from '@mui/icons-material/KeyboardArrowDownRounded';
import KeyboardArrowRightRounded from '@mui/icons-material/KeyboardArrowRightRounded';
import { parameterEditorUiSchema } from '../../schemas/ui-schemas.ts';
import { compactTemplates } from '../rjsf/index.ts';
import { useStore } from '../../state/store.ts';
import { DEFAULT_PARAM_TYPE, PARAMETER_TYPES } from '../../schemas/constants.ts';
import type { ParamDef } from '../../types/index.ts';

interface SharedParamEditorProps {
  fileIndex: number;
  paramName: string;
  parameterSchema: RJSFSchema;
}

export default function SharedParamEditor({ fileIndex, paramName, parameterSchema }: SharedParamEditorProps) {
  const files = useStore((s) => s.sharedParamFiles);
  const updateSharedParam = useStore((s) => s.updateSharedParam);
  const [advanced, setAdvanced] = useState(false);

  const file = files[fileIndex];
  if (!file) return null;

  const rawValue = file.parameters[paramName];
  const formData: ParamDef = typeof rawValue === 'string'
    ? { type: rawValue }
    : (rawValue ?? { type: DEFAULT_PARAM_TYPE });

  const advancedSetCount = Object.entries(formData).filter(([k, v]) => {
    if (k === 'type') return false;
    if (v == null || v === '') return false;
    if (Array.isArray(v) && v.length === 0) return false;
    return true;
  }).length;

  const handleChange = (e: IChangeEvent) => {
    if (e.formData) updateSharedParam(fileIndex, paramName, e.formData as ParamDef);
  };

  return (
    <Box>
      <Box sx={{ mb: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, flexWrap: 'wrap' }}>
          <Typography sx={{ fontSize: '0.82rem', color: 'text.secondary', fontFamily: '"JetBrains Mono", monospace' }}>
            {file.fileName}
          </Typography>
          <Typography sx={{ fontSize: '0.82rem', color: 'text.disabled', mx: 0.2 }}>/</Typography>
          <Typography sx={{ fontSize: '1.05rem', color: 'text.primary', fontWeight: 700, fontFamily: '"JetBrains Mono", monospace' }}>
            {paramName}
          </Typography>
        </Box>
      </Box>

      <FormControl fullWidth size="small" sx={{ mb: 2.5 }}>
        <InputLabel>Type</InputLabel>
        <Select
          value={PARAMETER_TYPES.includes(formData.type ?? '') ? formData.type : (PARAMETER_TYPES.find((t) => t.toLowerCase() === (formData.type ?? '').toLowerCase()) ?? DEFAULT_PARAM_TYPE)}
          label="Type"
          onChange={(e) => {
            const newType = e.target.value;
            const hasAdvanced = Object.keys(formData).some((k) => k !== 'type' && formData[k as keyof ParamDef] != null && formData[k as keyof ParamDef] !== '');
            if (hasAdvanced) {
              updateSharedParam(fileIndex, paramName, { ...formData, type: newType });
            } else {
              updateSharedParam(fileIndex, paramName, newType);
            }
          }}
        >
          {PARAMETER_TYPES.map((t) => (
            <MenuItem key={t} value={t}>
              <Typography sx={{ fontFamily: '"JetBrains Mono", monospace', fontSize: '0.85rem' }}>{t}</Typography>
            </MenuItem>
          ))}
        </Select>
      </FormControl>

      <Box sx={{ borderRadius: 2, border: 1, borderColor: 'divider', overflow: 'hidden' }}>
        <Box
          role="button"
          tabIndex={0}
          onClick={() => setAdvanced(!advanced)}
          onKeyDown={(e: React.KeyboardEvent) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); setAdvanced(!advanced); } }}
          sx={{
            display: 'flex', alignItems: 'center', gap: 1, py: 1, px: 2,
            cursor: 'pointer', userSelect: 'none',
            bgcolor: advanced ? 'rgba(223,73,38,0.02)' : 'transparent',
            '&:hover': { bgcolor: 'rgba(223,73,38,0.04)' },
            '&:focus-visible': { outline: '2px solid #DF4926', outlineOffset: -2, borderRadius: 2 },
          }}
        >
          {advanced
            ? <KeyboardArrowDownRounded sx={{ fontSize: 20, color: '#DF4926' }} />
            : <KeyboardArrowRightRounded sx={{ fontSize: 20, color: 'text.secondary' }} />}
          <TuneRounded sx={{ fontSize: 16, color: advanced ? '#DF4926' : 'text.secondary' }} />
          <Typography sx={{ fontWeight: 600, fontSize: '0.82rem', color: 'text.secondary', flex: 1 }}>
            Advanced Options
          </Typography>
          {advancedSetCount > 0 && !advanced && (
            <Box sx={{ px: 0.8, py: 0.15, borderRadius: 1, bgcolor: 'rgba(46,125,50,0.08)' }}>
              <Typography sx={{ fontSize: '0.7rem', fontWeight: 600, color: 'success.main' }}>
                {advancedSetCount} set
              </Typography>
            </Box>
          )}
        </Box>
        <Collapse in={advanced}>
          <Box sx={{ px: 2, pb: 2, pt: 1 }}>
            <Form
              schema={parameterSchema}
              uiSchema={parameterEditorUiSchema}
              formData={formData}
              validator={validator}
              onChange={handleChange}
              templates={compactTemplates}
              liveValidate
              showErrorList={false}
            >
              <div />
            </Form>
          </Box>
        </Collapse>
      </Box>
    </Box>
  );
}
