import type { RJSFSchema } from '@rjsf/utils';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import Chip from '@mui/material/Chip';
import { useStore } from '../../state/store.ts';
import { OPERATIONS_FIELD } from '../../schemas/constants.ts';
import { toParamDef } from '../../utils/param-def.ts';
import { snakeCaseNameError } from '../../utils/validation.ts';
import Breadcrumb from '../Breadcrumb.tsx';
import NameErrorBanner from '../NameErrorBanner.tsx';
import ParamDefinitionForm from '../ParamDefinitionForm.tsx';
import type { ParamDef } from '../../types/index.ts';

interface ContextPropertyEditorProps {
  fileIndex: number;
  propName: string;
  parameterSchema: RJSFSchema;
  operations: string[];
}

export default function ContextPropertyEditor({ fileIndex, propName, parameterSchema, operations }: ContextPropertyEditorProps) {
  const file = useStore((s) => s.contextFiles[fileIndex]);
  const updateContextProperty = useStore((s) => s.updateContextProperty);
  const enforceSnakeParams = useStore((s) => s.config.naming?.enforce_snake_case_parameters ?? false);

  if (!file) return null;

  const value = toParamDef(file.properties[propName]);
  const currentOps = (value as Record<string, unknown>)[OPERATIONS_FIELD] as string[] ?? [];

  const handleOpToggle = (op: string) => {
    const newOps = currentOps.includes(op)
      ? currentOps.filter((o) => o !== op)
      : [...currentOps, op];
    updateContextProperty(fileIndex, propName, { ...value, [OPERATIONS_FIELD]: newOps } as ParamDef);
  };

  return (
    <Box>
      <Box sx={{ mb: 3 }}>
        <Breadcrumb parts={[file.fileName, file.contextName, propName]} />
        <NameErrorBanner message={snakeCaseNameError(propName, enforceSnakeParams)} />
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
                  color: active ? 'primary.contrastText' : 'text.secondary',
                  border: '1.5px solid',
                  borderColor: active ? 'primary.main' : 'divider',
                  '&:hover': {
                    bgcolor: active ? 'primary.dark' : (t: { palette: { primary: { main: string } } }) => `${t.palette.primary.main}14`,
                    borderColor: 'primary.main',
                    color: active ? 'primary.contrastText' : 'primary.main',
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

      <ParamDefinitionForm
        value={value}
        onChange={(next) => updateContextProperty(fileIndex, propName, next)}
        parameterSchema={parameterSchema}
        managedFields={[OPERATIONS_FIELD]}
      />
    </Box>
  );
}
