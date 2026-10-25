import { describe, it, expect, beforeEach } from 'vitest';
import { withDefaults } from '../../utils/config-defaults.ts';
import { setSchemaDefaultConfig, useStore } from '../../state/store.ts';
import type { ConfigState } from '../../types/index.ts';

describe('withDefaults', () => {
  it('fills missing sections and fields and keeps the values already set', () => {
    const defaults = {
      naming: { casing: 'snake_case', enforce_snake_case_parameters: true },
      meta: { auto_tracking_creation_date: false },
    };
    const stored = { naming: { casing: 'camel_case' } };

    expect(withDefaults(stored, defaults)).toEqual({
      naming: { casing: 'camel_case', enforce_snake_case_parameters: true },
      meta: { auto_tracking_creation_date: false },
    });
  });

  it('keeps stored arrays and values whose shape differs from the default', () => {
    expect(withDefaults({ list: ['a'], flag: 'x' }, { list: [], flag: { nested: true } }))
      .toEqual({ list: ['a'], flag: 'x' });
  });
});

describe('schema defaults in the store', () => {
  let defaults: ConfigState;

  beforeEach(() => {
    useStore.getState().resetState();
    defaults = useStore.getState().config;
    useStore.temporal.getState().clear();
  });

  it('completes a restored config that predates newer schema fields, without an undo step', () => {
    const { meta: _meta, ...withoutMeta } = defaults;
    useStore.setState({ config: { ...withoutMeta, naming: { ...defaults.naming, casing: 'camel_case' } } as unknown as ConfigState });
    useStore.temporal.getState().clear();

    setSchemaDefaultConfig(defaults);

    const { config } = useStore.getState();
    expect(config.meta).toEqual(defaults.meta);
    expect(config.naming.casing).toBe('camel_case');
    expect(useStore.temporal.getState().pastStates).toHaveLength(0);
  });

  it('completes the config of a loaded project file', () => {
    useStore.getState().loadProject({ config: { outputs: { dart: 'lib/analytics' } } as ConfigState });

    const { config } = useStore.getState();
    expect(config.outputs.dart).toBe('lib/analytics');
    expect(config.naming).toEqual(defaults.naming);
  });
});
