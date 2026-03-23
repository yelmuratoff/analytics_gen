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
import ErrorOutlineRounded from '@mui/icons-material/ErrorOutlineRounded';
import { parameterEditorUiSchema } from '../../schemas/ui-schemas.ts';
import { compactTemplates } from '../rjsf/index.ts';
import { useStore } from '../../state/store.ts';
import {
  DEFAULT_PARAM_TYPE, PARAMETER_TYPES, SNAKE_CASE_PARAM, NON_NUMERIC_TYPES,
  PARAM_MUTUAL_EXCLUSIONS, STRING_ONLY_FIELDS, NUMERIC_ONLY_FIELDS,
} from '../../schemas/constants.ts';
import Breadcrumb from '../Breadcrumb.tsx';
import AdvancedSection from '../AdvancedSection.tsx';
import type { ParamDef } from '../../types/index.ts';

interface SharedParamEditorProps {
  fileIndex: number;
  paramName: string;
  parameterSchema: RJSFSchema;
}

export default function SharedParamEditor({ fileIndex, paramName, parameterSchema }: SharedParamEditorProps) {
  const files = useStore((s) => s.sharedParamFiles);
  const updateSharedParam = useStore((s) => s.updateSharedParam);
  const cfg = useStore((s) => s.config) as unknown as Record<string, Record<string, unknown>>;
  const enforceSnakeParams = cfg.naming?.enforce_snake_case_parameters as boolean ?? false;

  const file = files[fileIndex];
  if (!file) return null;

  const rawValue = file.parameters[paramName];
  const formData: ParamDef = typeof rawValue === 'string'
    ? { type: rawValue }
    : (rawValue ?? { type: DEFAULT_PARAM_TYPE });

  const nameError = enforceSnakeParams && !SNAKE_CASE_PARAM.test(paramName)
    ? `"${paramName}" must be snake_case (a-z, 0-9, _)` : null;

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const customValidate = useCallback((data: any, errors: FormValidation) => {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const e = errors as any;
    const baseType = data.type?.replace(/\?$/, '');
    const isStringLike = baseType === 'string';
    const isNumericLike = baseType ? !NON_NUMERIC_TYPES.has(baseType) : false;
    for (const [a, b] of PARAM_MUTUAL_EXCLUSIONS) {
      const valA = data[a as keyof ParamDef], valB = data[b as keyof ParamDef];
      const hasA = valA !== undefined && valA !== '' && !(Array.isArray(valA) && valA.length === 0);
      const hasB = valB !== undefined && valB !== '' && !(Array.isArray(valB) && valB.length === 0);
      if (hasA && hasB) e[b]?.addError(`${a} and ${b} cannot be used together`);
    }
    if (data.regex && data.regex.includes("'''")) e.regex?.addError("regex cannot contain triple quotes (''')");
    for (const f of STRING_ONLY_FIELDS) { if (data[f as keyof ParamDef] !== undefined && baseType && !isStringLike) e[f]?.addError(`${f} only applies to string type`); }
    for (const f of NUMERIC_ONLY_FIELDS) { if (data[f as keyof ParamDef] !== undefined && baseType && !isNumericLike) e[f]?.addError(`${f} only applies to numeric types`); }
    if (data.min_length !== undefined && data.max_length !== undefined && data.max_length < data.min_length) e.max_length?.addError('max_length must be >= min_length');
    if (data.min !== undefined && data.max !== undefined && data.max < data.min) e.max?.addError('max must be >= min');
    return errors;
  }, []);

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
        <Breadcrumb parts={[file.fileName, paramName]} />
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
