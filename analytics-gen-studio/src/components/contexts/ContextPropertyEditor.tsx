import Form from '@rjsf/mui';
import type { RJSFSchema } from '@rjsf/utils';
import type { IChangeEvent } from '@rjsf/core';
import validator from '@rjsf/validator-ajv8';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import Chip from '@mui/material/Chip';
import NavigateNextRounded from '@mui/icons-material/NavigateNextRounded';
import { parameterEditorUiSchema } from '../../schemas/ui-schemas.ts';
import { compactTemplates } from '../rjsf/index.ts';
import { useStore } from '../../state/store.ts';
import { DEFAULT_PARAM_TYPE } from '../../schemas/constants.ts';
import type { ParamDef } from '../../types/index.ts';

interface ContextPropertyEditorProps {
  fileIndex: number;
  propName: string;
  parameterSchema: RJSFSchema;
  /** Operations extracted from parameter.schema.json at load time */
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

  const currentOps = formData.operations ?? [];

  const handleChange = (e: IChangeEvent) => {
    if (e.formData) {
      const data = e.formData as ParamDef;
      updateContextProperty(fileIndex, propName, { ...data, operations: currentOps });
    }
  };

  const handleOpToggle = (op: string) => {
    const newOps = currentOps.includes(op)
      ? currentOps.filter((o) => o !== op)
      : [...currentOps, op];
    updateContextProperty(fileIndex, propName, { ...formData, operations: newOps });
  };

  const schemaWithoutOps = { ...parameterSchema };
  if (schemaWithoutOps.properties) {
    const { operations: _ops, ...restProps } = schemaWithoutOps.properties;
    schemaWithoutOps.properties = restProps;
  }

  return (
    <Box>
      <Box sx={{ mb: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.3, flexWrap: 'wrap' }}>
          <Typography sx={{ fontSize: '0.75rem', color: '#999', fontFamily: '"JetBrains Mono", monospace' }}>
            {file.fileName}
          </Typography>
          <NavigateNextRounded sx={{ fontSize: 14, color: '#ccc' }} />
          <Typography sx={{ fontSize: '0.75rem', color: '#999', fontFamily: '"JetBrains Mono", monospace' }}>
            {file.contextName}
          </Typography>
          <NavigateNextRounded sx={{ fontSize: 16, color: '#ccc' }} />
          <Typography sx={{ fontSize: '1.05rem', color: '#1A1A1A', fontWeight: 700, fontFamily: '"JetBrains Mono", monospace' }}>
            {propName}
          </Typography>
        </Box>
      </Box>

      <Box sx={{
        p: 2, mb: 3, borderRadius: 2.5,
        bgcolor: '#F7F8F2',
        border: '1px solid #EEEBE8',
      }}>
        <Typography sx={{
          fontWeight: 600, fontSize: '0.78rem', color: '#555', mb: 1.5,
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
                  fontSize: '0.75rem',
                  cursor: 'pointer',
                  transition: 'all 0.1s ease',
                  bgcolor: active ? '#DF4926' : 'transparent',
                  color: active ? '#fff' : '#7A7A7A',
                  border: '1.5px solid',
                  borderColor: active ? '#DF4926' : '#E8E4E0',
                  '&:hover': {
                    bgcolor: active ? '#C03A1C' : '#FAF7F4',
                    borderColor: '#DF4926',
                    color: active ? '#fff' : '#DF4926',
                  },
                }}
              />
            );
          })}
        </Box>
        {currentOps.length === 0 && (
          <Typography sx={{ fontSize: '0.72rem', color: '#bbb', mt: 1 }}>
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
