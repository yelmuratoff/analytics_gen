import type { RJSFSchema } from '@rjsf/utils';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import OpenInNewRounded from '@mui/icons-material/OpenInNewRounded';
import { useStore } from '../../state/store.ts';
import { toParamDef } from '../../utils/param-def.ts';
import { snakeCaseNameError } from '../../utils/validation.ts';
import Breadcrumb from '../Breadcrumb.tsx';
import NameErrorBanner from '../NameErrorBanner.tsx';
import ParamDefinitionForm from '../ParamDefinitionForm.tsx';

interface ParameterEditorProps {
  fileIndex: number;
  domain: string;
  eventName: string;
  paramName: string;
  parameterSchema: RJSFSchema;
  breadcrumb?: string[] | null;
}

export default function ParameterEditor({ fileIndex, domain, eventName, paramName, parameterSchema, breadcrumb }: ParameterEditorProps) {
  const event = useStore((s) => s.eventFiles[fileIndex]?.domains[domain]?.[eventName]);
  const updateParameter = useStore((s) => s.updateParameter);
  const setActiveTab = useStore((s) => s.setActiveTab);
  const setSelectedPath = useStore((s) => s.setSelectedPath);
  const enforceSnakeParams = useStore((s) => s.config.naming?.enforce_snake_case_parameters ?? false);

  if (!event) return null;
  const rawValue = event.parameters[paramName];

  const handleBreadcrumbClick = (index: number) => {
    if (!breadcrumb || index >= breadcrumb.length - 1) return;
    if (index === 0) {
      // File click — show file level
      setSelectedPath({ tab: 'events', fileIndex });
    } else if (index === 1) {
      // Domain click — show domain view
      setSelectedPath({ tab: 'events', fileIndex, domain });
    } else if (index === 2) {
      // Event click — show event editor
      setSelectedPath({ tab: 'events', fileIndex, domain, event: eventName });
    }
  };

  const breadcrumbEl = breadcrumb ? (
    <Breadcrumb parts={breadcrumb} onPartClick={handleBreadcrumbClick} />
  ) : null;

  // Shared ref
  if (rawValue === null) {
    return (
      <Box>
        <Box sx={{ mb: 3 }}>
          {breadcrumbEl}
        </Box>
        <Box sx={{
          p: 2.5, borderRadius: 1.5, border: '2px dashed', borderColor: (t: { palette: { brand: { contexts: string } } }) => `${t.palette.brand.contexts}40`,
          bgcolor: (t: { palette: { brand: { contexts: string } } }) => `${t.palette.brand.contexts}08`,
        }}>
          <Typography variant="subtitle1" sx={{ color: 'brand.contexts', mb: 0.5 }}>
            Shared Parameter
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 1.5 }}>
            Defined in Shared Parameters tab. Resolved at generation time.
          </Typography>
          <Button
            size="small"
            variant="outlined"
            startIcon={<OpenInNewRounded sx={{ fontSize: 14 }} />}
            onClick={() => {
              setActiveTab('shared');
              setSelectedPath(null);
            }}
            sx={{ fontSize: '0.78rem' }}
          >
            Go to Shared Params
          </Button>
        </Box>
      </Box>
    );
  }

  return (
    <Box>
      <Box sx={{ mb: 3 }}>
        {breadcrumbEl}
        <NameErrorBanner message={snakeCaseNameError(paramName, enforceSnakeParams)} />
      </Box>
      <ParamDefinitionForm
        value={toParamDef(rawValue)}
        onChange={(next) => updateParameter(fileIndex, domain, eventName, paramName, next)}
        parameterSchema={parameterSchema}
      />
    </Box>
  );
}
