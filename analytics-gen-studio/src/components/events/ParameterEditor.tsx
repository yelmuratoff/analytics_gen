import { useCallback } from 'react';
import Form from '@rjsf/mui';
import type { RJSFSchema, FormValidation } from '@rjsf/utils';
import type { IChangeEvent } from '@rjsf/core';
import validator from '@rjsf/validator-ajv8';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import Select from '@mui/material/Select';
import MenuItem from '@mui/material/MenuItem';
import FormControl from '@mui/material/FormControl';
import InputLabel from '@mui/material/InputLabel';
import Button from '@mui/material/Button';
import OpenInNewRounded from '@mui/icons-material/OpenInNewRounded';
import ErrorOutlineRounded from '@mui/icons-material/ErrorOutlineRounded';
import { parameterEditorUiSchema } from '../../schemas/ui-schemas.ts';
import { compactTemplates } from '../rjsf/index.ts';
import { useStore } from '../../state/store.ts';
import {
  DEFAULT_PARAM_TYPE, SNAKE_CASE_PARAM, NON_NUMERIC_TYPES,
  PARAM_MUTUAL_EXCLUSIONS, STRING_ONLY_FIELDS, NUMERIC_ONLY_FIELDS,
} from '../../schemas/constants.ts';
import Breadcrumb from '../Breadcrumb.tsx';
import AdvancedSection from '../AdvancedSection.tsx';
import type { ParamDef } from '../../types/index.ts';

interface ParameterEditorProps {
  fileIndex: number;
  domain: string;
  eventName: string;
  paramName: string;
  parameterSchema: RJSFSchema;
  parameterTypes: string[];
  breadcrumb?: string[] | null;
}

export default function ParameterEditor({ fileIndex, domain, eventName, paramName, parameterSchema, parameterTypes, breadcrumb }: ParameterEditorProps) {
  const files = useStore((s) => s.eventFiles);
  const updateParameter = useStore((s) => s.updateParameter);
  const setActiveTab = useStore((s) => s.setActiveTab);
  const setSelectedPath = useStore((s) => s.setSelectedPath);

  const file = files[fileIndex];
  if (!file) return null;
  const event = file.domains[domain]?.[eventName];
  if (!event) return null;
  const rawValue = event.parameters[paramName];

  const handleBreadcrumbClick = (index: number) => {
    if (!breadcrumb || index >= breadcrumb.length - 1) return;
    if (index === 0) {
      // File click — show file level
      setSelectedPath({ tab: 'events', fileIndex });
    } else if (index === 1) {
      // Domain click — show domain view
      setSelectedPath({ tab: 'events', fileIndex, domain });
    } else if (index === 2) {
      // Event click — show event editor
      setSelectedPath({ tab: 'events', fileIndex, domain, event: eventName });
    }
  };

  const breadcrumbEl = breadcrumb ? (
    <Breadcrumb parts={breadcrumb} onPartClick={handleBreadcrumbClick} />
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
            sx={{ fontSize: '0.78rem' }}
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

  const advancedSetCount = Object.entries(formData).filter(([k, v]) => {
    if (k === 'type') return false;
    if (v == null || v === '') return false;
    if (Array.isArray(v) && v.length === 0) return false;
    return true;
  }).length;

  const cfg = useStore((s) => s.config) as unknown as Record<string, Record<string, unknown>>;
  const enforceSnakeParams = cfg.naming?.enforce_snake_case_parameters as boolean ?? false;

  // Name-level error (shown as banner — can't be on a form field)
  const nameError = enforceSnakeParams && !SNAKE_CASE_PARAM.test(paramName)
    ? `"${paramName}" must be snake_case (a-z, 0-9, _)` : null;

  // Field-level errors via customValidate — validated directly from form data
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const customValidate = useCallback((data: any, errors: FormValidation) => {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const e = errors as any;
    const baseType = data.type?.replace(/\?$/, '');
    const isStringLike = baseType === 'string';
    const isNumericLike = baseType ? !NON_NUMERIC_TYPES.has(baseType) : false;

    // Mutual exclusion checks
    for (const [a, b] of PARAM_MUTUAL_EXCLUSIONS) {
      const valA = data[a as keyof ParamDef];
      const valB = data[b as keyof ParamDef];
      const hasA = valA !== undefined && valA !== '' && !(Array.isArray(valA) && valA.length === 0);
      const hasB = valB !== undefined && valB !== '' && !(Array.isArray(valB) && valB.length === 0);
      if (hasA && hasB) {
        e[b]?.addError(`${a} and ${b} cannot be used together`);
      }
    }
    // Regex triple quotes
    if (data.regex && data.regex.includes("'''")) {
      e.regex?.addError("regex cannot contain triple quotes (''')");
    }
    // String-only fields
    for (const field of STRING_ONLY_FIELDS) {
      if (data[field as keyof ParamDef] !== undefined && baseType && !isStringLike) {
        e[field]?.addError(`${field} only applies to string type`);
      }
    }
    // Numeric-only fields
    for (const field of NUMERIC_ONLY_FIELDS) {
      if (data[field as keyof ParamDef] !== undefined && baseType && !isNumericLike) {
        e[field]?.addError(`${field} only applies to numeric types`);
      }
    }
    // Range checks
    if (data.min_length !== undefined && data.max_length !== undefined && data.max_length < data.min_length) {
      e.max_length?.addError('max_length must be >= min_length');
    }
    if (data.min !== undefined && data.max !== undefined && data.max < data.min) {
      e.max?.addError('max must be >= min');
    }
    return errors;
  }, []);

  const header = (
    <Box sx={{ mb: 3 }}>
      {breadcrumbEl}
      {nameError && (
        <Box sx={{
          mt: 1.5, px: 2, py: 1.2, borderRadius: 1.5,
          bgcolor: 'rgba(211,47,47,0.06)', border: '1px solid rgba(211,47,47,0.2)',
          display: 'flex', alignItems: 'center', gap: 0.75,
        }}>
          <ErrorOutlineRounded sx={{ fontSize: 14, color: '#D32F2F', flexShrink: 0 }} />
          <Typography sx={{ fontSize: '0.78rem', color: '#D32F2F', fontWeight: 500 }}>{nameError}</Typography>
        </Box>
      )}
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
              <Typography sx={{ fontFamily: '"JetBrains Mono", monospace', fontSize: '0.85rem' }}>{t}</Typography>
            </MenuItem>
          ))}
        </Select>
      </FormControl>

      <AdvancedSection setCount={advancedSetCount}>
        <Form
          schema={parameterSchema}
          uiSchema={parameterEditorUiSchema}
          formData={formData}
          validator={validator}
          onChange={handleChange}
          customValidate={customValidate}
          templates={compactTemplates}
          showErrorList={false}
        >
          <div />
        </Form>
      </AdvancedSection>
    </Box>
  );
}
