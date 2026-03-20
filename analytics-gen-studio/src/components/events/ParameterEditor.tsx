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
import Button from '@mui/material/Button';
import NavigateNextRounded from '@mui/icons-material/NavigateNextRounded';
import TuneRounded from '@mui/icons-material/TuneRounded';
import KeyboardArrowDownRounded from '@mui/icons-material/KeyboardArrowDownRounded';
import KeyboardArrowRightRounded from '@mui/icons-material/KeyboardArrowRightRounded';
import OpenInNewRounded from '@mui/icons-material/OpenInNewRounded';
import { parameterEditorUiSchema } from '../../schemas/ui-schemas.ts';
import { compactTemplates } from '../rjsf/index.ts';
import { useStore } from '../../state/store.ts';
import { DEFAULT_PARAM_TYPE } from '../../schemas/constants.ts';
import type { ParamDef } from '../../types/index.ts';

interface ParameterEditorProps {
  fileIndex: number;
  domain: string;
  eventName: string;
  paramName: string;
  parameterSchema: RJSFSchema;
  /** Types extracted from parameter.schema.json at load time */
  parameterTypes: string[];
  breadcrumb?: string[] | null;
}

export default function ParameterEditor({ fileIndex, domain, eventName, paramName, parameterSchema, parameterTypes, breadcrumb }: ParameterEditorProps) {
  const files = useStore((s) => s.eventFiles);
  const updateParameter = useStore((s) => s.updateParameter);
  const setActiveTab = useStore((s) => s.setActiveTab);
  const setSelectedPath = useStore((s) => s.setSelectedPath);
  const [advanced, setAdvanced] = useState(false);

  const file = files[fileIndex];
  if (!file) return null;
  const event = file.domains[domain]?.[eventName];
  if (!event) return null;
  const rawValue = event.parameters[paramName];

  const handleBreadcrumbClick = (index: number) => {
    if (!breadcrumb || index >= breadcrumb.length - 1) return; // Don't navigate on last item (current)
    // index 0 = file, 1 = domain, 2 = event — navigate to event
    if (index === 2 || index === 1) {
      setSelectedPath({ tab: 'events', fileIndex, domain, event: eventName });
    }
  };

  const breadcrumbEl = breadcrumb && breadcrumb.length > 1 ? (
    <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.3, flexWrap: 'wrap' }}>
      {breadcrumb.map((part, i) => {
        const isLast = i === breadcrumb.length - 1;
        const isClickable = !isLast && i >= 1;
        return (
          <Box key={i} sx={{ display: 'flex', alignItems: 'center', gap: 0.3 }}>
            {i > 0 && <NavigateNextRounded sx={{ fontSize: isLast ? 16 : 14, color: '#ccc' }} />}
            <Typography
              onClick={isClickable ? () => handleBreadcrumbClick(i) : undefined}
              sx={{
                fontSize: isLast ? '1.05rem' : '0.75rem',
                color: isLast ? '#1A1A1A' : '#999',
                fontWeight: isLast ? 700 : 400,
                fontFamily: '"JetBrains Mono", monospace',
                ...(isClickable && {
                  cursor: 'pointer',
                  '&:hover': { color: '#DF4926' },
                }),
              }}>
              {part}
            </Typography>
          </Box>
        );
      })}
    </Box>
  ) : null;

  // Shared ref
  if (rawValue === null) {
    return (
      <Box>
        <Box sx={{ mb: 3 }}>
          {breadcrumbEl}
        </Box>
        <Box sx={{
          p: 2.5, borderRadius: 1.5, border: '2px dashed rgba(99,102,241,0.25)',
          bgcolor: 'rgba(99,102,241,0.03)',
        }}>
          <Typography variant="subtitle1" sx={{ color: '#6366F1', mb: 0.5 }}>
            Shared Parameter
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 1.5 }}>
            Defined in Shared Parameters tab. Resolved at generation time.
          </Typography>
          <Button
            size="small"
            variant="outlined"
            startIcon={<OpenInNewRounded sx={{ fontSize: 14 }} />}
            onClick={() => {
              setActiveTab('shared');
              setSelectedPath(null);
            }}
            sx={{ fontSize: '0.75rem' }}
          >
            Go to Shared Params
          </Button>
        </Box>
      </Box>
    );
  }

  const formData: ParamDef = typeof rawValue === 'string'
    ? { type: rawValue }
    : (rawValue ?? { type: DEFAULT_PARAM_TYPE });

  // Count filled advanced fields (everything except 'type')
  const advancedSetCount = Object.entries(formData).filter(([k, v]) => {
    if (k === 'type') return false;
    if (v == null || v === '') return false;
    if (Array.isArray(v) && v.length === 0) return false;
    return true;
  }).length;

  const header = (
    <Box sx={{ mb: 3 }}>
      {breadcrumbEl}
    </Box>
  );

  const handleChange = (e: IChangeEvent) => {
    if (e.formData) updateParameter(fileIndex, domain, eventName, paramName, e.formData as ParamDef);
  };

  return (
    <Box>
      {header}
      <FormControl fullWidth size="small" sx={{ mb: 2.5 }}>
        <InputLabel>Type</InputLabel>
        <Select
          value={parameterTypes.includes(formData.type ?? '') ? formData.type : (parameterTypes.find((t) => t.toLowerCase() === (formData.type ?? '').toLowerCase()) ?? DEFAULT_PARAM_TYPE)}
          label="Type"
          onChange={(e) => updateParameter(fileIndex, domain, eventName, paramName, e.target.value)}
        >
          {parameterTypes.map((t) => (
            <MenuItem key={t} value={t}>
              <Typography sx={{ fontFamily: '"JetBrains Mono", monospace', fontSize: '0.82rem' }}>{t}</Typography>
            </MenuItem>
          ))}
        </Select>
      </FormControl>

      {/* Advanced options - collapsible section */}
      <Box sx={{
        borderRadius: 2, border: '1px solid #EEEBE8', overflow: 'hidden',
      }}>
        <Box
          onClick={() => setAdvanced(!advanced)}
          sx={{
            display: 'flex', alignItems: 'center', gap: 1, py: 1, px: 2,
            cursor: 'pointer', userSelect: 'none',
            bgcolor: advanced ? 'rgba(223,73,38,0.02)' : 'transparent',
            '&:hover': { bgcolor: 'rgba(223,73,38,0.04)' },
          }}
        >
          {advanced
            ? <KeyboardArrowDownRounded sx={{ fontSize: 20, color: '#DF4926' }} />
            : <KeyboardArrowRightRounded sx={{ fontSize: 20, color: '#999' }} />}
          <TuneRounded sx={{ fontSize: 16, color: advanced ? '#DF4926' : '#999' }} />
          <Typography sx={{ fontWeight: 600, fontSize: '0.78rem', color: '#555', flex: 1 }}>
            Advanced Options
          </Typography>
          {advancedSetCount > 0 && !advanced && (
            <Box sx={{
              px: 0.8, py: 0.15, borderRadius: 1,
              bgcolor: 'rgba(46,125,50,0.08)',
            }}>
              <Typography sx={{ fontSize: '0.68rem', fontWeight: 600, color: '#2E7D32' }}>
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
