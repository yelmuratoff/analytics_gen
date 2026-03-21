import { useState } from 'react';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import TextField from '@mui/material/TextField';
import Switch from '@mui/material/Switch';
import Select from '@mui/material/Select';
import MenuItem from '@mui/material/MenuItem';
import FormControl from '@mui/material/FormControl';
import InputLabel from '@mui/material/InputLabel';
import Chip from '@mui/material/Chip';
import IconButton from '@mui/material/IconButton';
import InputAdornment from '@mui/material/InputAdornment';
import Collapse from '@mui/material/Collapse';
import Tooltip from '@mui/material/Tooltip';
import AddRounded from '@mui/icons-material/AddRounded';
import CloseRounded from '@mui/icons-material/CloseRounded';
import KeyboardArrowDownRounded from '@mui/icons-material/KeyboardArrowDownRounded';
import KeyboardArrowRightRounded from '@mui/icons-material/KeyboardArrowRightRounded';
import UnfoldMoreRounded from '@mui/icons-material/UnfoldMoreRounded';
import UnfoldLessRounded from '@mui/icons-material/UnfoldLessRounded';
import InputRounded from '@mui/icons-material/InputRounded';
import OutputRounded from '@mui/icons-material/OutputRounded';
import TrackChangesRounded from '@mui/icons-material/TrackChangesRounded';
import GavelRounded from '@mui/icons-material/GavelRounded';
import TextFieldsRounded from '@mui/icons-material/TextFieldsRounded';
import InfoOutlined from '@mui/icons-material/InfoOutlined';
import SettingsRounded from '@mui/icons-material/SettingsRounded';
import type { RJSFSchema } from '@rjsf/utils';
import { useStore } from '../../state/store.ts';

// Icon lookup from schema x-ui.icon values to MUI components
const iconMap: Record<string, React.ReactNode> = {
  input: <InputRounded sx={{ fontSize: 18, color: '#DF4926' }} />,
  output: <OutputRounded sx={{ fontSize: 18, color: '#DF4926' }} />,
  target: <TrackChangesRounded sx={{ fontSize: 18, color: '#DF4926' }} />,
  rule: <GavelRounded sx={{ fontSize: 18, color: '#DF4926' }} />,
  text_fields: <TextFieldsRounded sx={{ fontSize: 18, color: '#DF4926' }} />,
  info: <InfoOutlined sx={{ fontSize: 18, color: '#DF4926' }} />,
};

function getSectionIcon(schema: Record<string, unknown>) {
  const xui = schema['x-ui'] as Record<string, string> | undefined;
  const iconName = xui?.icon;
  return (iconName && iconMap[iconName]) ?? <SettingsRounded sx={{ fontSize: 18, color: '#DF4926' }} />;
}

// ── Reusable pieces ──

function Section({ title, icon, open, onToggle, filledCount, children }: {
  title: string; icon: React.ReactNode; open: boolean; onToggle: () => void; filledCount?: number; children: React.ReactNode;
}) {
  return (
    <Box sx={{ mb: 1, borderRadius: 2.5, border: '1px solid #EEEBE8', overflow: 'hidden' }}>
      <Box
        role="button"
        tabIndex={0}
        onClick={onToggle}
        onKeyDown={(e: React.KeyboardEvent) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); onToggle(); } }}
        sx={{
          display: 'flex', alignItems: 'center', gap: 1, py: 1.2, px: 2,
          cursor: 'pointer', userSelect: 'none',
          bgcolor: open ? 'rgba(223,73,38,0.02)' : 'transparent',
          '&:hover': { bgcolor: 'rgba(223,73,38,0.04)' },
          '&:focus-visible': { outline: '2px solid #DF4926', outlineOffset: -2, borderRadius: 2 },
        }}
      >
        {open
          ? <KeyboardArrowDownRounded sx={{ fontSize: 20, color: '#DF4926' }} />
          : <KeyboardArrowRightRounded sx={{ fontSize: 20, color: '#999' }} />}
        {icon}
        <Typography sx={{ fontWeight: 700, fontSize: '0.85rem', color: '#333', flex: 1 }}>{title}</Typography>
        {!open && filledCount != null && filledCount > 0 && (
          <Chip
            label={`${filledCount} set`}
            size="small"
            sx={{
              height: 20, fontSize: '0.68rem', fontWeight: 600,
              bgcolor: 'rgba(46,125,50,0.08)', color: '#2E7D32',
              '& .MuiChip-label': { px: 0.8 },
            }}
          />
        )}
      </Box>
      <Collapse in={open}>
        <Box sx={{ px: 2.5, pb: 2, pt: 0.75, display: 'flex', flexDirection: 'column', gap: 2 }}>
          {children}
        </Box>
      </Collapse>
    </Box>
  );
}

function FieldLabel({ label, hint }: { label: string; hint?: string }) {
  return (
    <Box>
      <Typography sx={{ fontWeight: 600, fontSize: '0.78rem', color: '#444', mb: 0.3 }}>{label}</Typography>
      {hint && <Typography sx={{ fontSize: '0.75rem', color: '#999', mb: 0.5, lineHeight: 1.4 }}>{hint}</Typography>}
    </Box>
  );
}

function Toggle({ label, hint, checked, onChange }: {
  label: string; hint?: string; checked: boolean; onChange: (v: boolean) => void;
}) {
  return (
    <Box
      onClick={() => onChange(!checked)}
      sx={{
        display: 'flex', alignItems: 'center', gap: 1.5, py: 0.6, px: 1,
        cursor: 'pointer', borderRadius: 2,
        '&:hover': { bgcolor: 'rgba(0,0,0,0.015)' },
      }}
    >
      <Switch
        checked={checked} size="small"
        sx={{
          '& .MuiSwitch-switchBase.Mui-checked': { color: '#DF4926' },
          '& .MuiSwitch-switchBase.Mui-checked + .MuiSwitch-track': { bgcolor: '#DF4926' },
        }}
      />
      <Box sx={{ flex: 1 }}>
        <Typography sx={{ fontWeight: 600, fontSize: '0.78rem', color: '#333' }}>{label}</Typography>
        {hint && <Typography sx={{ fontSize: '0.75rem', color: '#999', lineHeight: 1.4 }}>{hint}</Typography>}
      </Box>
    </Box>
  );
}

function PathList({ items, placeholder, onChange }: {
  items: string[]; placeholder: string; onChange: (items: string[]) => void;
}) {
  const [draft, setDraft] = useState('');
  const add = () => {
    const v = draft.trim();
    if (v && !items.includes(v)) { onChange([...items, v]); setDraft(''); }
  };
  return (
    <Box>
      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.8, mb: items.length ? 1 : 0 }}>
        {items.map((item, i) => (
          <Chip key={i} label={item} size="small"
            deleteIcon={<CloseRounded sx={{ fontSize: 14 }} />}
            onDelete={() => onChange(items.filter((_, j) => j !== i))}
            sx={{
              fontFamily: '"JetBrains Mono", monospace', fontSize: '0.75rem', height: 28,
              bgcolor: 'rgba(223,73,38,0.06)', color: '#333',
              '& .MuiChip-deleteIcon': { color: '#ccc', '&:hover': { color: '#D32F2F' } },
            }}
          />
        ))}
      </Box>
      <TextField size="small" fullWidth placeholder={placeholder} value={draft}
        onChange={(e) => setDraft(e.target.value)}
        onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); add(); } }}
        slotProps={{
          input: {
            endAdornment: draft.trim() ? (
              <InputAdornment position="end">
                <IconButton size="small" onClick={add} sx={{ color: '#DF4926' }}>
                  <AddRounded sx={{ fontSize: 18 }} />
                </IconButton>
              </InputAdornment>
            ) : null,
            sx: { fontSize: '0.8rem' },
          },
        }}
      />
    </Box>
  );
}

// ── Dynamic field renderer ──
// Reads schema type, title, description, enum, default, examples
// and renders the appropriate widget automatically.

function DynamicField({ fieldKey, schema, value, onChange }: {
  fieldKey: string;
  schema: Record<string, unknown>;
  value: unknown;
  onChange: (value: unknown) => void;
}) {
  const type = schema.type as string;
  const title = (schema.title as string) ?? fieldKey;
  const description = schema.description as string | undefined;
  const enumValues = schema.enum as string[] | undefined;
  const defaultVal = schema.default;
  const examples = schema.examples as unknown[] | undefined;
  const placeholder = examples?.[0] != null ? String(examples[0]) : (defaultVal != null ? String(defaultVal) : '');

  // Boolean → Toggle switch
  if (type === 'boolean') {
    return (
      <Toggle
        label={title}
        hint={description}
        checked={value as boolean ?? false}
        onChange={(v) => onChange(v)}
      />
    );
  }

  // String with enum → Select dropdown
  if (type === 'string' && enumValues) {
    return (
      <Box>
        <FieldLabel label={title} hint={description} />
        <FormControl size="small" fullWidth>
          <InputLabel>{title}</InputLabel>
          <Select value={value as string ?? ''} label={title}
            onChange={(e) => onChange(e.target.value)} sx={{ fontSize: '0.82rem' }}>
            {enumValues.map((opt) => (
              <MenuItem key={opt} value={opt}>{opt}</MenuItem>
            ))}
          </Select>
        </FormControl>
      </Box>
    );
  }

  // String → TextField
  if (type === 'string') {
    const isTemplate = fieldKey.includes('template');
    return (
      <Box>
        <FieldLabel label={title} hint={description} />
        <TextField size="small" fullWidth placeholder={placeholder}
          value={value as string ?? ''}
          onChange={(e) => onChange(e.target.value || undefined)}
          slotProps={{ input: { sx: { fontSize: '0.8rem', ...(isTemplate ? { fontFamily: '"JetBrains Mono", monospace' } : {}) } } }}
        />
      </Box>
    );
  }

  // Array of strings → PathList (chip-based)
  if (type === 'array') {
    const itemType = (schema.items as Record<string, unknown> | undefined)?.type;
    if (itemType === 'string' || !itemType) {
      return (
        <Box>
          <FieldLabel label={title} hint={description ? `${description} — type and press Enter` : 'Type and press Enter'} />
          <PathList
            items={value as string[] ?? []}
            placeholder={placeholder || 'Add item...'}
            onChange={(v) => onChange(v)}
          />
        </Box>
      );
    }
  }

  // Object (e.g. domain_aliases) → JSON-like display (simplified)
  if (type === 'object') {
    return (
      <Box>
        <FieldLabel label={title} hint={description} />
        <Typography sx={{ fontSize: '0.75rem', color: '#999', fontStyle: 'italic' }}>
          Edit via YAML preview
        </Typography>
      </Box>
    );
  }

  return null;
}

// ── Main ──

interface ConfigTabProps {
  configSchema: RJSFSchema;
}

export default function ConfigTab({ configSchema }: ConfigTabProps) {
  const config = useStore((s) => s.config);
  const updateConfig = useStore((s) => s.updateConfig);

  const sections = configSchema.properties ?? {};
  const sectionKeys = Object.keys(sections).filter((k) => {
    const s = sections[k] as Record<string, unknown>;
    return s.type === 'object' && s.properties;
  });

  const [openSections, setOpenSections] = useState<Set<string>>(() => new Set(sectionKeys.length > 0 ? [sectionKeys[0]] : []));
  const toggleSection = (key: string) => setOpenSections((prev) => {
    const next = new Set(prev);
    if (next.has(key)) next.delete(key); else next.add(key);
    return next;
  });
  const allExpanded = sectionKeys.length > 0 && sectionKeys.every((k) => openSections.has(k));

  return (
    <Box>
      <Box sx={{ mb: 3, display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
        <Box>
          <Typography variant="h4">Configuration</Typography>
          <Typography variant="caption">analytics_gen.yaml</Typography>
        </Box>
        {sectionKeys.length > 1 && (
          <Tooltip title={allExpanded ? 'Collapse all' : 'Expand all'} arrow>
            <IconButton size="small" onClick={() => setOpenSections(allExpanded ? new Set() : new Set(sectionKeys))} sx={{
              color: '#999', '&:hover': { color: '#DF4926', bgcolor: 'rgba(223,73,38,0.04)' },
            }}>
              {allExpanded ? <UnfoldLessRounded sx={{ fontSize: 20 }} /> : <UnfoldMoreRounded sx={{ fontSize: 20 }} />}
            </IconButton>
          </Tooltip>
        )}
      </Box>

      {Object.entries(sections).map(([sectionKey, sectionSchema], sectionIndex) => {
        const sec = sectionSchema as Record<string, unknown>;
        if (sec.type !== 'object' || !sec.properties) return null;
        const sectionTitle = (sec.title as string) ?? sectionKey;
        const sectionConfig = (config as unknown as Record<string, Record<string, unknown>>)[sectionKey] ?? {};
        const fields = sec.properties as Record<string, Record<string, unknown>>;
        const filledCount = Object.entries(fields).filter(([fk]) => {
          const val = sectionConfig[fk];
          if (val == null) return false;
          if (typeof val === 'boolean') return val === true;
          if (typeof val === 'string') return val !== '';
          if (Array.isArray(val)) return val.length > 0;
          if (typeof val === 'object') return Object.keys(val as object).length > 0;
          return true;
        }).length;

        return (
          <Section key={sectionKey} title={sectionTitle} icon={getSectionIcon(sec)} open={openSections.has(sectionKey)} onToggle={() => toggleSection(sectionKey)} filledCount={filledCount}>
            {Object.entries(fields).map(([fieldKey, fieldSchema]) => (
              <DynamicField
                key={fieldKey}
                fieldKey={fieldKey}
                schema={fieldSchema}
                value={sectionConfig[fieldKey]}
                onChange={(v) => {
                  updateConfig((c) => {
                    (c as unknown as Record<string, Record<string, unknown>>)[sectionKey][fieldKey] = v;
                  });
                }}
              />
            ))}
          </Section>
        );
      })}
    </Box>
  );
}
