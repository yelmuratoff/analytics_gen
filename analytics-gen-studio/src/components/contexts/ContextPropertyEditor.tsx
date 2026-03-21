import Form from '@rjsf/mui';
import type { RJSFSchema } from '@rjsf/utils';
import type { IChangeEvent } from '@rjsf/core';
import validator from '@rjsf/validator-ajv8';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import Chip from '@mui/material/Chip';
import { parameterEditorUiSchema } from '../../schemas/ui-schemas.ts';
import { compactTemplates } from '../rjsf/index.ts';
import { useStore } from '../../state/store.ts';
import { DEFAULT_PARAM_TYPE, OPERATIONS_FIELD } from '../../schemas/constants.ts';
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

  const file = files[fileIndex];
  if (!file) return null;

  const rawValue = file.properties[propName];
  const formData: ParamDef = typeof rawValue === 'string'
    ? { type: rawValue }
    : (rawValue ?? { type: DEFAULT_PARAM_TYPE });

  const currentOps = (formData as Record<string, unknown>)[OPERATIONS_FIELD] as string[] ?? [];

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
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, flexWrap: 'wrap' }}>
          <Typography sx={{ fontSize: '0.82rem', color: 'text.secondary', fontFamily: '"JetBrains Mono", monospace' }}>
            {file.fileName}
          </Typography>
          <Typography sx={{ fontSize: '0.82rem', color: 'text.disabled', mx: 0.2 }}>/</Typography>
          <Typography sx={{ fontSize: '0.82rem', color: 'text.secondary', fontFamily: '"JetBrains Mono", monospace' }}>
            {file.contextName}
          </Typography>
          <Typography sx={{ fontSize: '0.85rem', color: 'text.disabled', mx: 0.2 }}>/</Typography>
          <Typography sx={{ fontSize: '1.05rem', color: 'text.primary', fontWeight: 700, fontFamily: '"JetBrains Mono", monospace' }}>
            {propName}
          </Typography>
        </Box>
      </Box>

      <Box sx={{
        p: 2, mb: 3, borderRadius: 2.5,
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
                  bgcolor: active ? '#DF4926' : 'transparent',
                  color: active ? '#fff' : 'text.secondary',
                  border: '1.5px solid',
                  borderColor: active ? '#DF4926' : 'divider',
                  '&:hover': {
                    bgcolor: active ? '#C03A1C' : 'action.selected',
                    borderColor: '#DF4926',
                    color: active ? '#fff' : '#DF4926',
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

      <Form
        schema={schemaWithoutOps}
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
  );
}
