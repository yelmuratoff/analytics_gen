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
import Chip from '@mui/material/Chip';
import ErrorOutlineRounded from '@mui/icons-material/ErrorOutlineRounded';
import { parameterEditorUiSchema } from '../../schemas/ui-schemas.ts';
import { compactTemplates } from '../rjsf/index.ts';
import { useStore } from '../../state/store.ts';
import { DEFAULT_PARAM_TYPE, PARAMETER_TYPES, OPERATIONS_FIELD, SNAKE_CASE_PARAM } from '../../schemas/constants.ts';
import { useParameterValidation, countAdvancedFields } from '../../hooks/useParameterValidation.ts';
import Breadcrumb from '../Breadcrumb.tsx';
import AdvancedSection from '../AdvancedSection.tsx';
import type { ParamDef } from '../../types/index.ts';

interface ContextPropertyEditorProps {
  fileIndex: number;
  propName: string;
  parameterSchema: RJSFSchema;
  operations: string[];
}

export default function ContextPropertyEditor({ fileIndex, propName, parameterSchema, operations }: ContextPropertyEditorProps) {
  const files = useStore((s) => s.contextFiles);
  const updateContextProperty = useStore((s) => s.updateContextProperty);
  const cfg = useStore((s) => s.config) as unknown as Record<string, Record<string, unknown>>;
  const enforceSnakeParams = cfg.naming?.enforce_snake_case_parameters as boolean ?? false;

  const file = files[fileIndex];
  if (!file) return null;

  const rawValue = file.properties[propName];
  const formData: ParamDef = typeof rawValue === 'string'
    ? { type: rawValue }
    : (rawValue ?? { type: DEFAULT_PARAM_TYPE });

  const currentOps = (formData as Record<string, unknown>)[OPERATIONS_FIELD] as string[] ?? [];
  const nameError = enforceSnakeParams && !SNAKE_CASE_PARAM.test(propName)
    ? `"${propName}" must be snake_case (a-z, 0-9, _)` : null;

  const customValidate = useParameterValidation();
  const advancedSetCount = countAdvancedFields(formData, [OPERATIONS_FIELD]);

  const handleChange = (e: IChangeEvent) => {
    if (e.formData) {
      const data = e.formData as ParamDef;
      updateContextProperty(fileIndex, propName, { ...data, [OPERATIONS_FIELD]: currentOps } as unknown as ParamDef);
    }
  };

  const handleOpToggle = (op: string) => {
    const newOps = currentOps.includes(op)
      ? currentOps.filter((o) => o !== op)
      : [...currentOps, op];
    updateContextProperty(fileIndex, propName, { ...formData, [OPERATIONS_FIELD]: newOps } as unknown as ParamDef);
  };

  const schemaWithoutOps = { ...parameterSchema };
  if (schemaWithoutOps.properties && OPERATIONS_FIELD in schemaWithoutOps.properties) {
    const { [OPERATIONS_FIELD]: _ops, ...restProps } = schemaWithoutOps.properties;
    schemaWithoutOps.properties = restProps;
  }

  return (
    <Box>
      <Box sx={{ mb: 3 }}>
        <Breadcrumb parts={[file.fileName, file.contextName, propName]} />
        {nameError && (
          <Box sx={{
            mt: 1.5, px: 2, py: 1.2, borderRadius: 1.5,
            bgcolor: 'rgba(211,47,47,0.06)', border: '1px solid rgba(211,47,47,0.2)',
            display: 'flex', alignItems: 'center', gap: 0.75,
          }}>
            <ErrorOutlineRounded sx={{ fontSize: 14, color: 'error.main', flexShrink: 0 }} />
            <Typography sx={{ fontSize: '0.78rem', color: 'error.main', fontWeight: 500 }}>{nameError}</Typography>
          </Box>
        )}
      </Box>

      <Box sx={{
        p: 2, mb: 2.5, borderRadius: 2.5,
        bgcolor: 'action.hover',
        border: 1, borderColor: 'divider',
      }}>
        <Typography sx={{
          fontWeight: 600, fontSize: '0.82rem', color: 'text.secondary', mb: 1.5,
        }}>
          Operations
        </Typography>
        <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
          {operations.map((op) => {
            const active = currentOps.includes(op);
            return (
              <Chip
                key={op}
                label={op}
                size="small"
                onClick={() => handleOpToggle(op)}
                sx={{
                  fontWeight: 600,
                  fontSize: '0.78rem',
                  cursor: 'pointer',
                  transition: 'all 0.1s ease',
                  bgcolor: active ? 'primary.main' : 'transparent',
                  color: active ? '#fff' : 'text.secondary',
                  border: '1.5px solid',
                  borderColor: active ? 'primary.main' : 'divider',
                  '&:hover': {
                    bgcolor: active ? 'primary.dark' : (t: { palette: { primary: { main: string } } }) => `${t.palette.primary.main}14`,
                    borderColor: 'primary.main',
                    color: active ? '#fff' : 'primary.main',
                  },
                }}
              />
            );
          })}
        </Box>
        {currentOps.length === 0 && (
          <Typography sx={{ fontSize: '0.75rem', color: 'text.disabled', mt: 1 }}>
            Select operations this property supports
          </Typography>
        )}
      </Box>

      <FormControl fullWidth size="small" sx={{ mb: 2.5 }}>
        <InputLabel>Type</InputLabel>
        <Select
          value={PARAMETER_TYPES.includes(formData.type ?? '') ? formData.type : (PARAMETER_TYPES.find((t) => t.toLowerCase() === (formData.type ?? '').toLowerCase()) ?? DEFAULT_PARAM_TYPE)}
          label="Type"
          onChange={(e) => {
            updateContextProperty(fileIndex, propName, { ...formData, type: e.target.value, [OPERATIONS_FIELD]: currentOps } as unknown as ParamDef);
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
          schema={schemaWithoutOps}
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
