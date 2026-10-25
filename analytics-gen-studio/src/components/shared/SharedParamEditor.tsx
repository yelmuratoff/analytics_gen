import type { RJSFSchema } from '@rjsf/utils';
import Box from '@mui/material/Box';
import { useStore } from '../../state/store.ts';
import { toParamDef } from '../../utils/param-def.ts';
import { snakeCaseNameError } from '../../utils/validation.ts';
import Breadcrumb from '../Breadcrumb.tsx';
import NameErrorBanner from '../NameErrorBanner.tsx';
import ParamDefinitionForm from '../ParamDefinitionForm.tsx';

interface SharedParamEditorProps {
  fileIndex: number;
  paramName: string;
  parameterSchema: RJSFSchema;
}

export default function SharedParamEditor({ fileIndex, paramName, parameterSchema }: SharedParamEditorProps) {
  const file = useStore((s) => s.sharedParamFiles[fileIndex]);
  const updateSharedParam = useStore((s) => s.updateSharedParam);
  const enforceSnakeParams = useStore((s) => s.config.naming?.enforce_snake_case_parameters ?? false);

  if (!file) return null;

  return (
    <Box>
      <Box sx={{ mb: 3 }}>
        <Breadcrumb parts={[file.fileName, paramName]} />
        <NameErrorBanner message={snakeCaseNameError(paramName, enforceSnakeParams)} />
      </Box>
      <ParamDefinitionForm
        value={toParamDef(file.parameters[paramName])}
        onChange={(next) => updateSharedParam(fileIndex, paramName, next)}
        parameterSchema={parameterSchema}
      />
    </Box>
  );
}
