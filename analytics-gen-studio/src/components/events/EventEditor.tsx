import { useMemo } from 'react';
import type { RJSFSchema, ErrorSchema } from '@rjsf/utils';
import type { IChangeEvent } from '@rjsf/core';
import Form from '@rjsf/mui';
import validator from '@rjsf/validator-ajv8';
import Box from '@mui/material/Box';
import { eventEditorUiSchema } from '../../schemas/ui-schemas.ts';
import { compactTemplates } from '../rjsf/index.ts';
import { useStore } from '../../state/store.ts';
import Breadcrumb from '../Breadcrumb.tsx';
import type { EventDef } from '../../types/index.ts';

interface EventEditorProps {
  fileIndex: number;
  domain: string;
  eventName: string;
  eventEditorSchema: RJSFSchema;
  breadcrumb?: string[] | null;
}

export default function EventEditor({ fileIndex, domain, eventName, eventEditorSchema, breadcrumb }: EventEditorProps) {
  const files = useStore((s) => s.eventFiles);
  const config = useStore((s) => s.config);
  const updateEvent = useStore((s) => s.updateEvent);
  const setSelectedPath = useStore((s) => s.setSelectedPath);

  const file = files[fileIndex];
  if (!file) return null;
  const event = file.domains[domain]?.[eventName];
  if (!event) return null;

  const { parameters: _params, ...formData } = event;
  const cfg = config as unknown as Record<string, Record<string, unknown>>;
  const strictEventNames = cfg.rules?.strict_event_names as boolean ?? false;

  // Compute extraErrors from form data directly — no dependency on useValidation() so no re-render loop
  const extraErrors = useMemo(() => {
    const result: ErrorSchema = {};
    const customName = formData.event_name as string | undefined;
    if (strictEventNames && customName && (customName.includes('{') || customName.includes('}'))) {
      (result as Record<string, unknown>).event_name = {
        __errors: ['Cannot contain { } when strict_event_names is enabled'],
      };
    }
    return result;
  }, [formData.event_name, strictEventNames]);

  const handleChange = (e: IChangeEvent) => {
    if (e.formData) updateEvent(fileIndex, domain, eventName, e.formData as EventDef);
  };

  const handleBreadcrumbClick = (index: number) => {
    if (!breadcrumb || index >= breadcrumb.length - 1) return;
    if (index === 0) {
      setSelectedPath({ tab: 'events', fileIndex });
    } else if (index === 1) {
      setSelectedPath({ tab: 'events', fileIndex, domain });
    }
  };

  return (
    <Box>
      <Box sx={{ mb: 3 }}>
        {breadcrumb && <Breadcrumb parts={breadcrumb} onPartClick={handleBreadcrumbClick} />}
      </Box>
      <Form
        schema={eventEditorSchema}
        uiSchema={eventEditorUiSchema}
        formData={formData}
        validator={validator}
        onChange={handleChange}
        extraErrors={extraErrors}
        templates={compactTemplates}
        showErrorList={false}
      >
        <div />
      </Form>
    </Box>
  );
}
