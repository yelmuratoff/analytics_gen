import Form from '@rjsf/mui';
import type { RJSFSchema } from '@rjsf/utils';
import type { IChangeEvent } from '@rjsf/core';
import validator from '@rjsf/validator-ajv8';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import NavigateNextRounded from '@mui/icons-material/NavigateNextRounded';
import { parameterEditorUiSchema } from '../../schemas/ui-schemas.ts';
import { compactTemplates } from '../rjsf/index.ts';
import { useStore } from '../../state/store.ts';
import { DEFAULT_PARAM_TYPE } from '../../schemas/constants.ts';
import type { ParamDef } from '../../types/index.ts';

interface SharedParamEditorProps {
  fileIndex: number;
  paramName: string;
  parameterSchema: RJSFSchema;
}

export default function SharedParamEditor({ fileIndex, paramName, parameterSchema }: SharedParamEditorProps) {
  const files = useStore((s) => s.sharedParamFiles);
  const updateSharedParam = useStore((s) => s.updateSharedParam);

  const file = files[fileIndex];
  if (!file) return null;

  const rawValue = file.parameters[paramName];
  const formData: ParamDef = typeof rawValue === 'string'
    ? { type: rawValue }
    : (rawValue ?? { type: DEFAULT_PARAM_TYPE });

  const handleChange = (e: IChangeEvent) => {
    if (e.formData) updateSharedParam(fileIndex, paramName, e.formData as ParamDef);
  };

  return (
    <Box>
      <Box sx={{ mb: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.3, mb: 0.5 }}>
          <Typography sx={{ fontSize: '0.75rem', color: '#999', fontFamily: '"JetBrains Mono", monospace' }}>
            {file.fileName}
          </Typography>
          <NavigateNextRounded sx={{ fontSize: 14, color: '#ccc' }} />
          <Typography sx={{ fontSize: '0.75rem', color: '#DF4926', fontWeight: 600, fontFamily: '"JetBrains Mono", monospace' }}>
            {paramName}
          </Typography>
        </Box>
        <Typography variant="h5">
          {paramName}
        </Typography>
      </Box>
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
  );
}
