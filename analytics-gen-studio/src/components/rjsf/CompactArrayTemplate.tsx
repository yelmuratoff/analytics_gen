import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Grid from '@mui/material/Grid';
import AddRounded from '@mui/icons-material/AddRounded';
import type {
  ArrayFieldTemplateProps,
  ArrayFieldItemTemplateProps,
  IconButtonProps,
} from '@rjsf/utils';
import { getTemplate, getUiOptions, TranslatableString } from '@rjsf/utils';

/**
 * Compact ArrayFieldTemplate — light border instead of Paper elevation,
 * tighter spacing, styled "Add item" button.
 */
export default function CompactArrayTemplate(props: ArrayFieldTemplateProps) {
  const {
    canAdd, disabled, fieldPathId, uiSchema, items,
    onAddClick, readonly, registry, required, schema, title,
  } = props;
  const uiOptions = getUiOptions(uiSchema);
  const ArrayFieldDescriptionTemplate = getTemplate('ArrayFieldDescriptionTemplate', registry, uiOptions);
  const ArrayFieldTitleTemplate = getTemplate('ArrayFieldTitleTemplate', registry, uiOptions);

  return (
    <Box sx={{ border: 1, borderColor: 'divider', borderRadius: 2.5, p: 2, mb: 1.5 }}>
      <ArrayFieldTitleTemplate
        fieldPathId={fieldPathId}
        title={uiOptions.title || title}
        schema={schema}
        uiSchema={uiSchema}
        required={required}
        registry={registry}
      />
      <ArrayFieldDescriptionTemplate
        fieldPathId={fieldPathId}
        description={uiOptions.description || schema.description}
        schema={schema}
        uiSchema={uiSchema}
        registry={registry}
      />
      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 0.5 }}>
        {items}
      </Box>
      {canAdd && (
        <Button
          startIcon={<AddRounded sx={{ fontSize: 16 }} />}
          onClick={onAddClick}
          disabled={disabled || readonly}
          size="small"
          sx={{
            mt: 1.5,
            color: '#DF4926', fontWeight: 600, fontSize: '0.74rem',
            textTransform: 'none', px: 1,
            '&:hover': { bgcolor: 'rgba(223,73,38,0.06)' },
          }}
        >
          Add item
        </Button>
      )}
    </Box>
  );
}

/** Compact array item — no Paper wrapper, inline layout */
export function CompactArrayItemTemplate(props: ArrayFieldItemTemplateProps) {
  const { children, hasToolbar, buttonsProps, uiSchema, registry } = props;
  const uiOptions = getUiOptions(uiSchema);
  const ArrayFieldItemButtonsTemplate = getTemplate('ArrayFieldItemButtonsTemplate', registry, uiOptions);

  return (
    <Grid container alignItems="center" sx={{ mb: 0.5 }}>
      <Grid size="grow" sx={{ overflow: 'auto' }}>
        {children}
      </Grid>
      {hasToolbar && (
        <Grid>
          <ArrayFieldItemButtonsTemplate
            {...buttonsProps}
            style={{ flex: 1, paddingLeft: 4, paddingRight: 4, fontWeight: 'bold', minWidth: 0 }}
          />
        </Grid>
      )}
    </Grid>
  );
}

/** Compact Add button — replaces the huge orange circle "+" with a text button */
export function CompactAddButton(props: IconButtonProps) {
  const { registry, uiSchema, color: _color, ...rest } = props;
  const { translateString } = registry;
  return (
    <Button
      {...rest}
      color={undefined}
      startIcon={<AddRounded sx={{ fontSize: 16 }} />}
      size="small"
      sx={{
        color: '#DF4926', fontWeight: 600, fontSize: '0.74rem',
        textTransform: 'none', px: 1.5, mt: 0.5,
        '&:hover': { bgcolor: 'rgba(223,73,38,0.06)' },
      }}
    >
      {translateString(TranslatableString.AddItemButton)}
    </Button>
  );
}
