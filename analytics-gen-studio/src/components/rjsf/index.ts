import type { TemplatesType } from '@rjsf/utils';
import { generateTemplates } from '@rjsf/mui';
import CompactArrayTemplate, { CompactArrayItemTemplate, CompactAddButton } from './CompactArrayTemplate.tsx';

// Get the full default MUI button templates, then override only AddButton
const muiDefaults = generateTemplates();
const defaultButtons = muiDefaults.ButtonTemplates!;

/** Custom RJSF templates — compact arrays + small Add button */
export const compactTemplates: Partial<TemplatesType> = {
  ArrayFieldTemplate: CompactArrayTemplate,
  ArrayFieldItemTemplate: CompactArrayItemTemplate,
  ButtonTemplates: {
    ...defaultButtons,
    AddButton: CompactAddButton,
  },
};
