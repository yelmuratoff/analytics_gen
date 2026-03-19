import type { RJSFSchema } from '@rjsf/utils';
import type { IChangeEvent } from '@rjsf/core';
import Form from '@rjsf/mui';
import validator from '@rjsf/validator-ajv8';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import NavigateNextRounded from '@mui/icons-material/NavigateNextRounded';
import { eventEditorUiSchema } from '../../schemas/ui-schemas.ts';
import { compactTemplates } from '../rjsf/index.ts';
import { useStore } from '../../state/store.ts';
import type { EventDef } from '../../types/index.ts';

interface EventEditorProps {
  fileIndex: number;
  domain: string;
  eventName: string;
  /** Schema derived from events.schema.json at load time */
  eventEditorSchema: RJSFSchema;
  breadcrumb?: string[] | null;
}

export default function EventEditor({ fileIndex, domain, eventName, eventEditorSchema, breadcrumb }: EventEditorProps) {
  const files = useStore((s) => s.eventFiles);
  const updateEvent = useStore((s) => s.updateEvent);

  const file = files[fileIndex];
  if (!file) return null;
  const event = file.domains[domain]?.[eventName];
  if (!event) return null;

  // Build formData from event, excluding 'parameters' (managed by tree UI)
  const { parameters: _params, ...formData } = event;

  const handleChange = (e: IChangeEvent) => {
    if (e.formData) updateEvent(fileIndex, domain, eventName, e.formData as EventDef);
  };

  return (
    <Box>
      <Box sx={{ mb: 3 }}>
        {breadcrumb && breadcrumb.length > 1 && (
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.3, flexWrap: 'wrap' }}>
            {breadcrumb.map((part, i) => (
              <Box key={i} sx={{ display: 'flex', alignItems: 'center', gap: 0.3 }}>
                {i > 0 && <NavigateNextRounded sx={{ fontSize: i === breadcrumb.length - 1 ? 16 : 14, color: '#ccc' }} />}
                <Typography sx={{
                  fontSize: i === breadcrumb.length - 1 ? '1.05rem' : '0.75rem',
                  color: i === breadcrumb.length - 1 ? '#1A1A1A' : '#999',
                  fontWeight: i === breadcrumb.length - 1 ? 700 : 400,
                  fontFamily: '"JetBrains Mono", monospace',
                }}>
                  {part}
                </Typography>
              </Box>
            ))}
          </Box>
        )}
      </Box>
      <Form
        schema={eventEditorSchema}
        uiSchema={eventEditorUiSchema}
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
