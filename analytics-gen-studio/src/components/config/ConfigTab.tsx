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
import AddRounded from '@mui/icons-material/AddRounded';
import CloseRounded from '@mui/icons-material/CloseRounded';
import KeyboardArrowDownRounded from '@mui/icons-material/KeyboardArrowDownRounded';
import KeyboardArrowRightRounded from '@mui/icons-material/KeyboardArrowRightRounded';
import FolderRounded from '@mui/icons-material/FolderRounded';
import OutputRounded from '@mui/icons-material/OutputRounded';
import TuneRounded from '@mui/icons-material/TuneRounded';
import GavelRounded from '@mui/icons-material/GavelRounded';
import AbcRounded from '@mui/icons-material/AbcRounded';
import DataObjectRounded from '@mui/icons-material/DataObjectRounded';
import { useStore } from '../../state/store.ts';
import type { ConfigState } from '../../types/index.ts';

// ── Reusable pieces ──

function Section({ icon, title, defaultOpen = true, children }: {
  icon: React.ReactNode; title: string; defaultOpen?: boolean; children: React.ReactNode;
}) {
  const [open, setOpen] = useState(defaultOpen);
  return (
    <Box sx={{
      mb: 1, borderRadius: 2.5,
      border: '1px solid #EEEBE8',
      overflow: 'hidden',
    }}>
      <Box
        onClick={() => setOpen(!open)}
        sx={{
          display: 'flex', alignItems: 'center', gap: 1, py: 1.2, px: 2,
          cursor: 'pointer', userSelect: 'none',
          bgcolor: open ? 'rgba(223,73,38,0.02)' : 'transparent',
          '&:hover': { bgcolor: 'rgba(223,73,38,0.04)' },
        }}
      >
        {open
          ? <KeyboardArrowDownRounded sx={{ fontSize: 20, color: '#DF4926' }} />
          : <KeyboardArrowRightRounded sx={{ fontSize: 20, color: '#999' }} />}
        <Box sx={{ color: '#DF4926', display: 'flex' }}>{icon}</Box>
        <Typography sx={{ fontWeight: 700, fontSize: '0.85rem', color: '#333', flex: 1 }}>{title}</Typography>
      </Box>
      <Collapse in={open}>
        <Box sx={{ px: 2.5, pb: 2.5, pt: 1, display: 'flex', flexDirection: 'column', gap: 2.5 }}>
          {children}
        </Box>
      </Collapse>
    </Box>
  );
}

function Field({ label, hint, children }: {
  label: string; hint?: string; children: React.ReactNode;
}) {
  return (
    <Box>
      <Typography sx={{ fontWeight: 600, fontSize: '0.78rem', color: '#444', mb: 0.3 }}>{label}</Typography>
      {hint && <Typography sx={{ fontSize: '0.68rem', color: '#999', mb: 0.8, lineHeight: 1.4 }}>{hint}</Typography>}
      {children}
    </Box>
  );
}

function Toggle({ label, hint, checked, onChange }: {
  label: string; hint: string; checked: boolean; onChange: (v: boolean) => void;
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
        <Typography sx={{ fontSize: '0.66rem', color: '#999', lineHeight: 1.4 }}>{hint}</Typography>
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
    if (v && !items.includes(v)) {
      onChange([...items, v]);
      setDraft('');
    }
  };

  return (
    <Box>
      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.8, mb: items.length ? 1 : 0 }}>
        {items.map((item, i) => (
          <Chip
            key={i}
            label={item}
            size="small"
            deleteIcon={<CloseRounded sx={{ fontSize: 14 }} />}
            onDelete={() => onChange(items.filter((_, j) => j !== i))}
            sx={{
              fontFamily: '"JetBrains Mono", monospace', fontSize: '0.72rem', height: 28,
              bgcolor: 'rgba(223,73,38,0.06)', color: '#333',
              '& .MuiChip-deleteIcon': { color: '#ccc', '&:hover': { color: '#D32F2F' } },
            }}
          />
        ))}
      </Box>
      <TextField
        size="small" fullWidth placeholder={placeholder} value={draft}
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

const input = { sx: { fontSize: '0.8rem' } };
const mono = { sx: { fontSize: '0.8rem', fontFamily: '"JetBrains Mono", monospace' } };

// ── Type-safe updater ──
// If ConfigState changes, TypeScript will error on every `set()` call
// that references a removed/renamed field — zero chance of silent drift.

// ── Main ──

export default function ConfigTab() {
  const config = useStore((s) => s.config);
  const updateConfig = useStore((s) => s.updateConfig);

  const set = <K extends keyof ConfigState>(
    section: K,
    key: keyof ConfigState[K],
    value: ConfigState[K][typeof key],
  ) => {
    updateConfig((c) => { (c[section] as Record<string, unknown>)[key as string] = value; });
  };

  return (
    <Box>
      <Box sx={{ mb: 3 }}>
        <Typography variant="h4">Configuration</Typography>
        <Typography variant="caption">analytics_gen.yaml</Typography>
      </Box>

      {/* ── Inputs ── */}
      <Section icon={<FolderRounded sx={{ fontSize: 18 }} />} title="Inputs">
        <Field label="Events directory" hint="Relative path to YAML event files">
          <TextField size="small" fullWidth placeholder="events"
            value={config.inputs.events}
            onChange={(e) => set('inputs', 'events', e.target.value)}
            slotProps={{ input }} />
        </Field>
        <Field label="Shared parameters" hint="Paths to shared parameter files — type and press Enter">
          <PathList items={config.inputs.shared_parameters} placeholder="shared_parameters.yaml"
            onChange={(v) => set('inputs', 'shared_parameters', v)} />
        </Field>
        <Field label="Contexts" hint="Paths to context definition files">
          <PathList items={config.inputs.contexts} placeholder="user_properties.yaml"
            onChange={(v) => set('inputs', 'contexts', v)} />
        </Field>
        <Field label="Custom imports" hint="Dart import URIs to include in generated files">
          <PathList items={config.inputs.imports} placeholder="package:my_app/models.dart"
            onChange={(v) => set('inputs', 'imports', v)} />
        </Field>
      </Section>

      {/* ── Outputs ── */}
      <Section icon={<OutputRounded sx={{ fontSize: 18 }} />} title="Outputs">
        <Field label="Dart output path" hint="Where generated Dart code will be written">
          <TextField size="small" fullWidth placeholder="lib/src/analytics/generated"
            value={config.outputs.dart}
            onChange={(e) => set('outputs', 'dart', e.target.value)}
            slotProps={{ input }} />
        </Field>
        <Field label="Documentation path" hint="Optional — required when docs target is enabled">
          <TextField size="small" fullWidth placeholder="docs/analytics"
            value={config.outputs.docs ?? ''}
            onChange={(e) => set('outputs', 'docs', e.target.value || undefined)}
            slotProps={{ input }} />
        </Field>
        <Field label="Exports path" hint="Optional — required when CSV/JSON/SQL targets are enabled">
          <TextField size="small" fullWidth placeholder="exports/analytics"
            value={config.outputs.exports ?? ''}
            onChange={(e) => set('outputs', 'exports', e.target.value || undefined)}
            slotProps={{ input }} />
        </Field>
      </Section>

      {/* ── Targets ── */}
      <Section icon={<TuneRounded sx={{ fontSize: 18 }} />} title="Generation Targets">
        <Toggle label="Tracking Plan" hint="Include runtime tracking plan in generated Dart code"
          checked={config.targets.plan} onChange={(v) => set('targets', 'plan', v)} />
        <Toggle label="Documentation" hint="Generate Markdown documentation from event definitions"
          checked={config.targets.docs} onChange={(v) => set('targets', 'docs', v)} />
        <Toggle label="CSV Export" hint="Generate CSV export of events and parameters"
          checked={config.targets.csv} onChange={(v) => set('targets', 'csv', v)} />
        <Toggle label="JSON Export" hint="Generate JSON export of events and parameters"
          checked={config.targets.json} onChange={(v) => set('targets', 'json', v)} />
        <Toggle label="SQL Export" hint="Generate SQL export (e.g., BigQuery schema)"
          checked={config.targets.sql} onChange={(v) => set('targets', 'sql', v)} />
        <Toggle label="Test Matchers" hint="Generate test matchers for package:test to verify analytics calls"
          checked={config.targets.test_matchers} onChange={(v) => set('targets', 'test_matchers', v)} />
      </Section>

      {/* ── Rules ── */}
      <Section icon={<GavelRounded sx={{ fontSize: 18 }} />} title="Validation Rules">
        <Toggle label="Strict Event Names" hint="Treat { } in event names as an error to prevent high-cardinality names"
          checked={config.rules.strict_event_names} onChange={(v) => set('rules', 'strict_event_names', v)} />
        <Toggle label="Include Event Description" hint="Include 'description' as a parameter in generated analytics map"
          checked={config.rules.include_event_description} onChange={(v) => set('rules', 'include_event_description', v)} />
        <Toggle label="Enforce Centrally Defined Parameters" hint="All parameters must be defined in shared files — no inline definitions"
          checked={config.rules.enforce_centrally_defined_parameters} onChange={(v) => set('rules', 'enforce_centrally_defined_parameters', v)} />
        <Toggle label="Prevent Event Parameter Duplicates" hint="Prevent defining parameters that already exist in shared files"
          checked={config.rules.prevent_event_parameter_duplicates} onChange={(v) => set('rules', 'prevent_event_parameter_duplicates', v)} />
      </Section>

      {/* ── Naming ── */}
      <Section icon={<AbcRounded sx={{ fontSize: 18 }} />} title="Naming Strategy">
        <Field label="Event name casing">
          <FormControl size="small" fullWidth>
            <InputLabel>Casing</InputLabel>
            <Select value={config.naming.casing} label="Casing"
              onChange={(e) => set('naming', 'casing', e.target.value)}
              sx={{ fontSize: '0.82rem' }}>
              <MenuItem value="snake_case">snake_case</MenuItem>
              <MenuItem value="title_case">Title Case</MenuItem>
              <MenuItem value="original">original</MenuItem>
            </Select>
          </FormControl>
        </Field>
        <Toggle label="Enforce Snake Case Domains" hint="Validate that domain keys match ^[a-z0-9_]+$"
          checked={config.naming.enforce_snake_case_domains} onChange={(v) => set('naming', 'enforce_snake_case_domains', v)} />
        <Toggle label="Enforce Snake Case Parameters" hint="Validate that parameter identifiers match ^[a-z][a-z0-9_]*$"
          checked={config.naming.enforce_snake_case_parameters} onChange={(v) => set('naming', 'enforce_snake_case_parameters', v)} />
        <Field label="Event name template" hint="Placeholders: {domain}, {domain_alias}, {event}">
          <TextField size="small" fullWidth placeholder="{domain}: {event}"
            value={config.naming.event_name_template}
            onChange={(e) => set('naming', 'event_name_template', e.target.value)}
            slotProps={{ input: mono }} />
        </Field>
        <Field label="Identifier template" hint="Same placeholders as event name template">
          <TextField size="small" fullWidth placeholder="{domain}: {event}"
            value={config.naming.identifier_template}
            onChange={(e) => set('naming', 'identifier_template', e.target.value)}
            slotProps={{ input: mono }} />
        </Field>
      </Section>

      {/* ── Meta ── */}
      <Section icon={<DataObjectRounded sx={{ fontSize: 18 }} />} title="Meta">
        <Toggle label="Auto Track Creation Date" hint="Automatically record when each event was first seen via a ledger file"
          checked={config.meta.auto_tracking_creation_date} onChange={(v) => set('meta', 'auto_tracking_creation_date', v)} />
        <Toggle label="Include Meta in Parameters" hint="Include added_in, deprecated_in etc. in generated event parameters map"
          checked={config.meta.include_meta_in_parameters} onChange={(v) => set('meta', 'include_meta_in_parameters', v)} />
      </Section>
    </Box>
  );
}
