import type { RJSFSchema } from '@rjsf/utils';
import type { IChangeEvent } from '@rjsf/core';
import Form from '@rjsf/mui';
import validator from '@rjsf/validator-ajv8';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import { eventEditorUiSchema } from '../../schemas/ui-schemas.ts';
import { useStore } from '../../state/store.ts';
import type { EventDef } from '../../types/index.ts';

const eventSchema: RJSFSchema = {
  type: 'object',
  properties: {
    description: { type: 'string', title: 'Description', default: 'No description provided' },
    event_name: { type: 'string', title: 'Custom Event Name' },
    identifier: { type: 'string', title: 'Unique Identifier' },
    deprecated: { type: 'boolean', title: 'Deprecated', default: false },
    replacement: { type: 'string', title: 'Replacement Event' },
    added_in: { type: 'string', title: 'Added In Version' },
    deprecated_in: { type: 'string', title: 'Deprecated In Version' },
    dual_write_to: { type: 'array', title: 'Dual Write To', items: { type: 'string' } },
  },
};

interface EventEditorProps {
  fileIndex: number;
  domain: string;
  eventName: string;
}

export default function EventEditor({ fileIndex, domain, eventName }: EventEditorProps) {
  const files = useStore((s) => s.eventFiles);
  const updateEvent = useStore((s) => s.updateEvent);

  const file = files[fileIndex];
  if (!file) return null;
  const event = file.domains[domain]?.[eventName];
  if (!event) return null;

  const formData = {
    description: event.description,
    event_name: event.event_name,
    identifier: event.identifier,
    deprecated: event.deprecated,
    replacement: event.replacement,
    added_in: event.added_in,
    deprecated_in: event.deprecated_in,
    dual_write_to: event.dual_write_to,
  };

  const handleChange = (e: IChangeEvent) => {
    if (e.formData) updateEvent(fileIndex, domain, eventName, e.formData as EventDef);
  };

  return (
    <Box>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h5">
          {eventName}
        </Typography>
        <Typography variant="caption">{domain}</Typography>
      </Box>
      <Form
        schema={eventSchema}
        uiSchema={eventEditorUiSchema}
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
