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
import Button from '@mui/material/Button';
import OpenInNewRounded from '@mui/icons-material/OpenInNewRounded';
import ErrorOutlineRounded from '@mui/icons-material/ErrorOutlineRounded';
import { parameterEditorUiSchema } from '../../schemas/ui-schemas.ts';
import { compactTemplates } from '../rjsf/index.ts';
import { useStore } from '../../state/store.ts';
import { DEFAULT_PARAM_TYPE, SNAKE_CASE_PARAM } from '../../schemas/constants.ts';
import { useParameterValidation, countAdvancedFields } from '../../hooks/useParameterValidation.ts';
import Breadcrumb from '../Breadcrumb.tsx';
import AdvancedSection from '../AdvancedSection.tsx';
import type { ParamDef } from '../../types/index.ts';

interface ParameterEditorProps {
  fileIndex: number;
  domain: string;
  eventName: string;
  paramName: string;
  parameterSchema: RJSFSchema;
  parameterTypes: string[];
  breadcrumb?: string[] | null;
}

export default function ParameterEditor({ fileIndex, domain, eventName, paramName, parameterSchema, parameterTypes, breadcrumb }: ParameterEditorProps) {
  const files = useStore((s) => s.eventFiles);
  const updateParameter = useStore((s) => s.updateParameter);
  const setActiveTab = useStore((s) => s.setActiveTab);
  const setSelectedPath = useStore((s) => s.setSelectedPath);

  const file = files[fileIndex];
  if (!file) return null;
  const event = file.domains[domain]?.[eventName];
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

  const formData: ParamDef = typeof rawValue === 'string'
    ? { type: rawValue }
    : (rawValue ?? { type: DEFAULT_PARAM_TYPE });

  const advancedSetCount = countAdvancedFields(formData);

  const cfg = useStore((s) => s.config) as unknown as Record<string, Record<string, unknown>>;
  const enforceSnakeParams = cfg.naming?.enforce_snake_case_parameters as boolean ?? false;

  const nameError = enforceSnakeParams && !SNAKE_CASE_PARAM.test(paramName)
    ? `"${paramName}" must be snake_case (a-z, 0-9, _)` : null;

  const customValidate = useParameterValidation();

  const header = (
    <Box sx={{ mb: 3 }}>
      {breadcrumbEl}
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
  );

  const handleChange = (e: IChangeEvent) => {
    if (e.formData) updateParameter(fileIndex, domain, eventName, paramName, e.formData as ParamDef);
  };

  return (
    <Box>
      {header}
      <FormControl fullWidth size="small" sx={{ mb: 2.5 }}>
        <InputLabel>Type</InputLabel>
        <Select
          value={parameterTypes.includes(formData.type ?? '') ? formData.type : (parameterTypes.find((t) => t.toLowerCase() === (formData.type ?? '').toLowerCase()) ?? DEFAULT_PARAM_TYPE)}
          label="Type"
          onChange={(e) => updateParameter(fileIndex, domain, eventName, paramName, e.target.value)}
        >
          {parameterTypes.map((t) => (
            <MenuItem key={t} value={t}>
              <Typography sx={{ fontFamily: '"JetBrains Mono", monospace', fontSize: '0.85rem' }}>{t}</Typography>
            </MenuItem>
          ))}
        </Select>
      </FormControl>

      <AdvancedSection setCount={advancedSetCount}>
        <Form
          schema={parameterSchema}
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
