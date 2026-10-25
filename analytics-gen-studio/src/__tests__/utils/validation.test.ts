import { describe, it, expect, beforeEach } from 'vitest';
import type { FormValidation } from '@rjsf/utils';
import { useStore } from '../../state/store.ts';
import { computeValidation, paramViolations, validateParamForm } from '../../utils/validation.ts';
import type { ParamDef } from '../../types/index.ts';

function validate() {
  const { config, eventFiles, sharedParamFiles, contextFiles } = useStore.getState();
  return computeValidation(config, eventFiles, sharedParamFiles, contextFiles);
}

function messages() {
  return validate().map((e) => e.message);
}

function addParam(name: string, val: ParamDef | string | null) {
  useStore.getState().addParameter(0, 'auth', 'login', name, val);
}

function setupEvent() {
  const s = useStore.getState();
  s.addEventFile('test.yaml');
  s.addDomain(0, 'auth');
  s.addEvent(0, 'auth', 'login');
}

describe('computeValidation', () => {
  beforeEach(() => useStore.getState().resetState());

  it('passes with schema defaults', () => {
    expect(validate()).toHaveLength(0);
  });

  it('requires a dart output path', () => {
    useStore.getState().updateConfig((c) => { c.outputs.dart = ''; });
    expect(messages()).toContain('Dart output path is required');
  });

  it('rejects a non-snake_case domain', () => {
    useStore.getState().addEventFile('t.yaml');
    useStore.getState().addDomain(0, 'MyDomain');
    expect(messages()).toContain('Domain "MyDomain" must be snake_case');
  });

  it('accepts a snake_case domain', () => {
    useStore.getState().addEventFile('t.yaml');
    useStore.getState().addDomain(0, 'my_domain');
    useStore.getState().addEvent(0, 'my_domain', 'e');
    expect(validate()).toHaveLength(0);
  });

  it('rejects placeholders in event_name when strict_event_names is on', () => {
    setupEvent();
    useStore.getState().updateEvent(0, 'auth', 'login', { event_name: 'Auth {x}', parameters: {} });
    expect(messages()).toContain('event_name cannot contain { } when strict_event_names is enabled');
  });

  it('allows placeholders in event_name when strict_event_names is off', () => {
    setupEvent();
    useStore.getState().updateConfig((c) => { c.rules.strict_event_names = false; });
    useStore.getState().updateEvent(0, 'auth', 'login', { event_name: 'Auth {x}', parameters: {} });
    expect(validate()).toHaveLength(0);
  });

  it('rejects a non-snake_case parameter name', () => {
    setupEvent();
    addParam('BadName', 'string');
    expect(messages()).toContain('"BadName" must be snake_case (a-z, 0-9, _)');
  });

  it('attaches navigation fields to parameter errors', () => {
    setupEvent();
    addParam('p', { type: 'string', identifier: 'CamelCase' });
    expect(validate()).toEqual([expect.objectContaining({
      tab: 'events', fileIndex: 0, domain: 'auth', event: 'login', parameter: 'p',
    })]);
  });

  it('skips definition checks for a compact string parameter and a shared reference', () => {
    setupEvent();
    addParam('method', 'string');
    addParam('session_id', null);
    expect(validate()).toHaveLength(0);
  });

  it('detects an event file without domains', () => {
    useStore.getState().addEventFile('empty.yaml');
    expect(messages()).toContain('File has no domains');
  });

  it('detects duplicate event file names', () => {
    useStore.getState().addEventFile('a.yaml');
    useStore.getState().addEventFile('a.yaml');
    expect(messages()).toContain('Duplicate file name: a.yaml');
  });

  it('validates parameters inside shared parameter files', () => {
    useStore.getState().addSharedParamFile('s.yaml');
    useStore.getState().addSharedParam(0, 'bad_param', { type: 'string', dart_type: 'X', allowed_values: ['a'] });
    expect(validate()).toEqual([expect.objectContaining({ tab: 'shared', fileIndex: 0, parameter: 'bad_param' })]);
  });

  it('detects duplicate shared file names', () => {
    useStore.getState().addSharedParamFile('s.yaml');
    useStore.getState().addSharedParamFile('s.yaml');
    expect(messages()).toContain('Duplicate file name: s.yaml');
  });

  it('validates properties inside context files', () => {
    useStore.getState().addContextFile('c.yaml', 'ctx');
    useStore.getState().addContextProperty(0, 'count', { type: 'string', min: 0 });
    expect(validate()).toEqual([expect.objectContaining({ tab: 'contexts', fileIndex: 0, contextProperty: 'count' })]);
  });

  it('detects duplicate context file names', () => {
    useStore.getState().addContextFile('c.yaml', 'ctx');
    useStore.getState().addContextFile('c.yaml', 'ctx2');
    expect(messages()).toContain('Duplicate file name: c.yaml');
  });

  it('requires a context name', () => {
    useStore.getState().loadProject({ contextFiles: [{ fileName: 'c.yaml', contextName: '', properties: {} }] });
    expect(messages()).toContain('Context name cannot be empty');
  });
});

describe('paramViolations', () => {
  it('rejects dart_type together with allowed_values', () => {
    expect(paramViolations({ type: 'string', dart_type: 'X', allowed_values: ['a'] }))
      .toContainEqual({ field: 'allowed_values', message: 'dart_type and allowed_values cannot be used together' });
  });

  it('rejects triple quotes in a regex', () => {
    expect(paramViolations({ type: 'string', regex: "a'''b" }))
      .toEqual([{ field: 'regex', message: "regex cannot contain triple quotes (''')" }]);
  });

  it('rejects max below min and max_length below min_length', () => {
    expect(paramViolations({ type: 'int', min: 10, max: 5 })).toEqual([{ field: 'max', message: 'max must be >= min' }]);
    expect(paramViolations({ type: 'string', min_length: 10, max_length: 3 }))
      .toEqual([{ field: 'max_length', message: 'max_length must be >= min_length' }]);
  });

  it('rejects length rules on a non-string type', () => {
    expect(paramViolations({ type: 'int', min_length: 1 }).map((v) => v.field)).toEqual(['min_length']);
  });

  it.each(['string', 'string?'])('allows length rules on %s', (type) => {
    expect(paramViolations({ type, min_length: 1, max_length: 50 })).toEqual([]);
  });

  it('rejects range rules on a non-numeric type', () => {
    expect(paramViolations({ type: 'string', min: 0, max: 10 }).map((v) => v.field)).toEqual(['min', 'max']);
  });

  it.each(['int', 'double', 'double?', 'num', 'num?'])('allows range rules on %s', (type) => {
    expect(paramViolations({ type, min: 0, max: 100 })).toEqual([]);
  });

  it('rejects a non-snake_case identifier', () => {
    expect(paramViolations({ type: 'string', identifier: 'CamelCase' }))
      .toEqual([{ field: 'identifier', message: 'identifier "CamelCase" must be snake_case' }]);
  });
});

describe('validateParamForm', () => {
  it('adds each violation to the field that breaks it', () => {
    const added: Record<string, string[]> = { max: [], identifier: [] };
    const errors = {
      max: { addError: (m: string) => added.max.push(m) },
      identifier: { addError: (m: string) => added.identifier.push(m) },
    } as unknown as FormValidation<ParamDef>;

    validateParamForm({ type: 'int', min: 10, max: 5, identifier: 'Bad' }, errors);

    expect(added).toEqual({
      max: ['max must be >= min'],
      identifier: ['identifier "Bad" must be snake_case'],
    });
  });
});
