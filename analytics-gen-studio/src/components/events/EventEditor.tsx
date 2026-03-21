import type { RJSFSchema } from '@rjsf/utils';
import type { IChangeEvent } from '@rjsf/core';
import Form from '@rjsf/mui';
import validator from '@rjsf/validator-ajv8';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import { eventEditorUiSchema } from '../../schemas/ui-schemas.ts';
import { compactTemplates } from '../rjsf/index.ts';
import { useStore } from '../../state/store.ts';
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
  const updateEvent = useStore((s) => s.updateEvent);
  const setSelectedPath = useStore((s) => s.setSelectedPath);

  const file = files[fileIndex];
  if (!file) return null;
  const event = file.domains[domain]?.[eventName];
  if (!event) return null;

  const { parameters: _params, ...formData } = event;

  const handleChange = (e: IChangeEvent) => {
    if (e.formData) updateEvent(fileIndex, domain, eventName, e.formData as EventDef);
  };

  const handleBreadcrumbClick = (index: number) => {
    if (!breadcrumb || index >= breadcrumb.length - 1) return;
    if (index === 2 || index === 1) {
      setSelectedPath({ tab: 'events', fileIndex, domain, event: eventName });
    }
  };

  return (
    <Box>
      <Box sx={{ mb: 3 }}>
        {breadcrumb && breadcrumb.length > 1 && (
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, flexWrap: 'nowrap', overflow: 'hidden' }}>
            {breadcrumb.map((part, i) => {
              const isLast = i === breadcrumb.length - 1;
              const isClickable = !isLast && i >= 1;
              return (
                <Box key={i} sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                  {i > 0 && (
                    <Typography sx={{ fontSize: isLast ? '0.85rem' : '0.78rem', color: 'text.disabled', mx: 0.2 }}>/</Typography>
                  )}
                  <Typography
                    component={isClickable ? 'button' : 'span'}
                    onClick={isClickable ? () => handleBreadcrumbClick(i) : undefined}
                    onKeyDown={isClickable ? (e: React.KeyboardEvent) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); handleBreadcrumbClick(i); } } : undefined}
                    tabIndex={isClickable ? 0 : undefined}
                    sx={{
                      fontSize: isLast ? '1.05rem' : '0.82rem',
                      color: isLast ? 'text.primary' : 'text.secondary',
                      fontWeight: isLast ? 700 : 400,
                      fontFamily: '"JetBrains Mono", monospace',
                      background: 'none', border: 'none', p: 0, borderRadius: 0.5,
                      overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
                      maxWidth: isLast ? 'none' : 120, flexShrink: isLast ? 0 : 1,
                      ...(isClickable && {
                        cursor: 'pointer',
                        '&:hover': { color: '#DF4926' },
                        '&:focus-visible': { outline: '2px solid #DF4926', outlineOffset: 2 },
                      }),
                    }}>
                    {part}
                  </Typography>
                </Box>
              );
            })}
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
