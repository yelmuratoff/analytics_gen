import { useId } from 'react';
import Form from '@rjsf/mui';
import type { RJSFSchema } from '@rjsf/utils';
import type { IChangeEvent } from '@rjsf/core';
import validator from '@rjsf/validator-ajv8';
import Typography from '@mui/material/Typography';
import Select from '@mui/material/Select';
import MenuItem from '@mui/material/MenuItem';
import FormControl from '@mui/material/FormControl';
import InputLabel from '@mui/material/InputLabel';
import { parameterEditorUiSchema } from '../schemas/ui-schemas.ts';
import { DEFAULT_PARAM_TYPE, PARAMETER_TYPES } from '../schemas/constants.ts';
import { validateParamForm } from '../utils/validation.ts';
import { compactTemplates } from './rjsf/index.ts';
import AdvancedSection from './AdvancedSection.tsx';
import type { ParamDef } from '../types/index.ts';

interface ParamDefinitionFormProps {
  value: ParamDef;
  onChange: (value: ParamDef) => void;
  parameterSchema: RJSFSchema;
  /** Fields edited outside this form: hidden from it and carried over from `value` on every change. */
  managedFields?: string[];
}

function selectableType(type: string | undefined): string {
  const current = type ?? '';
  if (PARAMETER_TYPES.includes(current)) return current;
  return PARAMETER_TYPES.find((t) => t.toLowerCase() === current.toLowerCase()) ?? DEFAULT_PARAM_TYPE;
}

function withoutFields(schema: RJSFSchema, fields: string[]): RJSFSchema {
  if (fields.length === 0 || !schema.properties) return schema;
  const properties = Object.fromEntries(
    Object.entries(schema.properties).filter(([key]) => !fields.includes(key)),
  );
  return { ...schema, properties };
}

function countAdvancedFields(value: ParamDef, excludeFields: string[]): number {
  const exclude = new Set(['type', ...excludeFields]);
  return Object.entries(value).filter(([k, v]) => {
    if (exclude.has(k)) return false;
    if (v == null || v === '') return false;
    if (Array.isArray(v) && v.length === 0) return false;
    return true;
  }).length;
}

function pickFields(value: ParamDef, fields: string[]): Partial<ParamDef> {
  const source = value as Record<string, unknown>;
  return Object.fromEntries(fields.filter((f) => f in source).map((f) => [f, source[f]])) as Partial<ParamDef>;
}

export default function ParamDefinitionForm({ value, onChange, parameterSchema, managedFields = [] }: ParamDefinitionFormProps) {
  const typeLabelId = useId();
  const managedValues = pickFields(value, managedFields);

  const handleFormChange = (e: IChangeEvent) => {
    if (e.formData) onChange({ ...(e.formData as ParamDef), ...managedValues });
  };

  return (
    <>
      <FormControl fullWidth size="small" sx={{ mb: 2.5 }}>
        <InputLabel id={typeLabelId}>Type</InputLabel>
        <Select
          labelId={typeLabelId}
          value={selectableType(value.type)}
          label="Type"
          onChange={(e) => onChange({ ...value, type: e.target.value })}
        >
          {PARAMETER_TYPES.map((t) => (
            <MenuItem key={t} value={t}>
              <Typography sx={{ fontFamily: '"JetBrains Mono", monospace', fontSize: '0.85rem' }}>{t}</Typography>
            </MenuItem>
          ))}
        </Select>
      </FormControl>

      <AdvancedSection setCount={countAdvancedFields(value, managedFields)}>
        <Form
          schema={withoutFields(parameterSchema, managedFields)}
          uiSchema={parameterEditorUiSchema}
          formData={value}
          validator={validator}
          onChange={handleFormChange}
          customValidate={validateParamForm}
          templates={compactTemplates}
          showErrorList={false}
        >
          <div />
        </Form>
      </AdvancedSection>
    </>
  );
}
