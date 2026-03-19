import Form from '@rjsf/mui';
import type { RJSFSchema } from '@rjsf/utils';
import type { IChangeEvent } from '@rjsf/core';
import validator from '@rjsf/validator-ajv8';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import { parameterEditorUiSchema } from '../../schemas/ui-schemas.ts';
import { useStore } from '../../state/store.ts';
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
    : (rawValue ?? { type: 'string' });

  const handleChange = (e: IChangeEvent) => {
    if (e.formData) updateSharedParam(fileIndex, paramName, e.formData as ParamDef);
  };

  return (
    <Box>
      <Box sx={{ mb: 4 }}>
        <Typography sx={{ fontWeight: 800, fontSize: '1.2rem', color: '#000', letterSpacing: '-0.02em' }}>
          {paramName}
        </Typography>
        <Typography variant="caption">{file.fileName}</Typography>
      </Box>
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
