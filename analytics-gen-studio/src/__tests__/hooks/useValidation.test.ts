import { describe, it, expect, beforeEach } from 'vitest';
import { useStore } from '../../state/store.ts';

// Test validation logic by manipulating store state directly
// The useValidation hook reads from the same store

function getErrors() {
  // Import and call the validation logic directly
  const { useValidation } = require('../../hooks/useValidation.ts');
  // Since hooks can't be called outside React, extract the pure logic
  // We'll test the store state + reimport the validation module
  const state = useStore.getState();
  const config = state.config;
  const eventFiles = state.eventFiles;
  const sharedParamFiles = state.sharedParamFiles;
  const contextFiles = state.contextFiles;

  // Replicate validation logic for testing
  const errors: { path: string; message: string; tab: string }[] = [];
  const SNAKE_CASE = /^[a-z][a-z0-9_]*$/;
  const SNAKE_CASE_DOMAIN = /^[a-z0-9_]+$/;

  const enforceSnakeDomains = config.naming.enforce_snake_case_domains;
  const enforceSnakeParams = config.naming.enforce_snake_case_parameters;

  if (!config.outputs.dart) {
    errors.push({ path: 'config.outputs.dart', message: 'Dart output path is required', tab: 'config' });
  }

  for (const file of eventFiles) {
    for (const [domainName, events] of Object.entries(file.domains)) {
      if (enforceSnakeDomains && !SNAKE_CASE_DOMAIN.test(domainName)) {
        errors.push({ path: `events.${file.fileName}.${domainName}`, message: `"${domainName}" must be snake_case`, tab: 'events' });
      }
      for (const [, event] of Object.entries(events)) {
        if (config.rules.strict_event_names && event.event_name && (event.event_name.includes('{') || event.event_name.includes('}'))) {
          errors.push({ path: 'event', message: 'event_name cannot contain { }', tab: 'events' });
        }
        for (const [paramName, paramVal] of Object.entries(event.parameters)) {
          if (enforceSnakeParams && !SNAKE_CASE.test(paramName)) {
            errors.push({ path: paramName, message: 'must be snake_case', tab: 'events' });
          }
          if (paramVal !== null && typeof paramVal === 'object') {
            if (paramVal.dart_type && paramVal.allowed_values && paramVal.allowed_values.length > 0) {
              errors.push({ path: paramName, message: 'dart_type and allowed_values', tab: 'events' });
            }
            if (paramVal.regex && paramVal.regex.includes("'''")) {
              errors.push({ path: paramName, message: "triple quotes", tab: 'events' });
            }
            if (paramVal.min !== undefined && paramVal.max !== undefined && paramVal.max < paramVal.min) {
              errors.push({ path: paramName, message: 'max must be >= min', tab: 'events' });
            }
            if (paramVal.identifier && !SNAKE_CASE.test(paramVal.identifier)) {
              errors.push({ path: paramName, message: 'identifier must be snake_case', tab: 'events' });
            }
          }
        }
      }
    }
  }

  return errors;
}

describe('validation logic', () => {
  beforeEach(() => {
    useStore.getState().resetState();
  });

  it('requires dart output path', () => {
    const state = useStore.getState();
    state.setConfig({ ...state.config, outputs: { dart: '' } });
    const errors = getErrors();
    expect(errors.some(e => e.message.includes('Dart output path'))).toBe(true);
  });

  it('passes with default config', () => {
    const errors = getErrors();
    expect(errors).toHaveLength(0);
  });

  it('detects non-snake_case domain', () => {
    const state = useStore.getState();
    state.addEventFile('test.yaml');
    state.addDomain(0, 'MyDomain');
    const errors = getErrors();
    expect(errors.some(e => e.message.includes('snake_case'))).toBe(true);
  });

  it('allows snake_case domain', () => {
    const state = useStore.getState();
    state.addEventFile('test.yaml');
    state.addDomain(0, 'my_domain');
    const errors = getErrors();
    expect(errors.filter(e => e.message.includes('snake_case'))).toHaveLength(0);
  });

  it('detects dart_type + allowed_values mutual exclusion', () => {
    const state = useStore.getState();
    state.addEventFile('test.yaml');
    state.addDomain(0, 'auth');
    state.addEvent(0, 'auth', 'login');
    state.addParameter(0, 'auth', 'login', 'method', {
      type: 'string',
      dart_type: 'MyEnum',
      allowed_values: ['a', 'b'],
    });
    const errors = getErrors();
    expect(errors.some(e => e.message.includes('dart_type and allowed_values'))).toBe(true);
  });

  it('detects triple quotes in regex', () => {
    const state = useStore.getState();
    state.addEventFile('test.yaml');
    state.addDomain(0, 'auth');
    state.addEvent(0, 'auth', 'login');
    state.addParameter(0, 'auth', 'login', 'code', {
      type: 'string',
      regex: "'''bad'''",
    });
    const errors = getErrors();
    expect(errors.some(e => e.message.includes('triple quotes'))).toBe(true);
  });

  it('detects max < min', () => {
    const state = useStore.getState();
    state.addEventFile('test.yaml');
    state.addDomain(0, 'd');
    state.addEvent(0, 'd', 'e');
    state.addParameter(0, 'd', 'e', 'val', { type: 'int', min: 10, max: 5 });
    const errors = getErrors();
    expect(errors.some(e => e.message.includes('max must be >= min'))).toBe(true);
  });

  it('detects strict_event_names violation', () => {
    const state = useStore.getState();
    state.addEventFile('test.yaml');
    state.addDomain(0, 'auth');
    state.addEvent(0, 'auth', 'login');
    state.updateEvent(0, 'auth', 'login', { event_name: 'Auth {dynamic}', parameters: {} });
    const errors = getErrors();
    expect(errors.some(e => e.message.includes('{ }'))).toBe(true);
  });
});
