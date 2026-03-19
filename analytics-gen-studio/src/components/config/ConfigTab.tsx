import Form from '@rjsf/mui';
import type { RJSFSchema } from '@rjsf/utils';
import type { IChangeEvent } from '@rjsf/core';
import validator from '@rjsf/validator-ajv8';
import { configUiSchema } from '../../schemas/ui-schemas.ts';
import { useStore } from '../../state/store.ts';
import type { ConfigState } from '../../types/index.ts';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';

interface ConfigTabProps {
  schema: RJSFSchema;
}

export default function ConfigTab({ schema }: ConfigTabProps) {
  const config = useStore((s) => s.config);
  const setConfig = useStore((s) => s.setConfig);

  const handleChange = (e: IChangeEvent) => {
    if (e.formData) setConfig(e.formData as ConfigState);
  };

  return (
    <Box>
      <Box sx={{ mb: 4 }}>
        <Typography sx={{ fontWeight: 800, fontSize: '1.3rem', color: '#000', letterSpacing: '-0.03em' }}>
          Configuration
        </Typography>
        <Typography variant="caption">analytics_gen.yaml</Typography>
      </Box>
      <Form
        schema={schema}
        uiSchema={configUiSchema}
        formData={config}
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
