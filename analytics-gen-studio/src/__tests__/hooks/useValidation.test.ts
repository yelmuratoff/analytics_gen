import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useStore } from '../../state/store.ts';
import { applySchemaConstants, NUMERIC_ONLY_FIELDS } from '../../schemas/constants.ts';
import { useValidation, refreshValidation } from '../../hooks/useValidation.ts';

const schemaRules = {
  defaultEventDescription: 'No description provided',
  snakeCaseDomainPattern: /^[a-z0-9_]+$/,
  snakeCaseParamPattern: /^[a-z][a-z0-9_]*$/,
};
const loadedNumericOnlyFields = [...NUMERIC_ONLY_FIELDS];

describe('useValidation', () => {
  beforeEach(() => {
    useStore.getState().resetState();
    useStore.getState().addContextFile('c.yaml', 'ctx');
    useStore.getState().addContextProperty(0, 'count', { type: 'string', min: 0 });
  });

  afterEach(() => {
    applySchemaConstants({ ...schemaRules, numericOnlyFields: loadedNumericOnlyFields });
    refreshValidation();
  });

  it('recomputes errors when schema rules arrive after the project is loaded', () => {
    applySchemaConstants({ ...schemaRules, numericOnlyFields: [] });
    refreshValidation();
    const { result } = renderHook(() => useValidation());
    expect(result.current).toEqual([]);

    act(() => {
      applySchemaConstants({ ...schemaRules, numericOnlyFields: ['min'] });
      refreshValidation();
    });

    expect(result.current.map((e) => e.message)).toEqual(['min only applies to numeric types']);
  });
});
