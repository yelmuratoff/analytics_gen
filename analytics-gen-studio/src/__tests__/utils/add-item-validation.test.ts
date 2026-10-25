import { describe, it, expect } from 'vitest';
import { newNameError } from '../../utils/validation.ts';
import { SNAKE_CASE_DOMAIN, SNAKE_CASE_PARAM } from '../../schemas/constants.ts';

describe('newNameError', () => {
  describe('empty input', () => {
    it('rejects empty string', () => {
      expect(newNameError('')).toBe('Name cannot be empty');
    });
  });

  describe('duplicate names', () => {
    it('rejects existing name', () => {
      expect(newNameError('auth', { existingNames: ['auth', 'user'] })).toBe('Name already exists');
    });

    it('accepts new name', () => {
      expect(newNameError('purchase', { existingNames: ['auth'] })).toBeNull();
    });
  });

  describe('YAML key validation', () => {
    it.each([
      ':', '{', '}', '[', ']', '&', '*', '?', '|', '>', '<', '!', '%', '@', '`', '#', ',', "'", '"', '\\',
    ])('rejects YAML-unsafe char: %s', (char) => {
      expect(newNameError(`test${char}name`)).toBe('Contains characters that break YAML (: { } [ ] etc.)');
    });

    it('rejects key starting with number', () => {
      expect(newNameError('123abc')).toBe('Must start with a letter or _, only letters, numbers, _');
    });

    it.each(['auth_login', '_internal', 'path/to.file', 'camelCase'])('accepts %s without a name pattern', (name) => {
      expect(newNameError(name)).toBeNull();
    });
  });

  describe('name pattern', () => {
    it('rejects a name that breaks the pattern', () => {
      expect(newNameError('MyDomain', { namePattern: SNAKE_CASE_PARAM }))
        .toBe('Must be snake_case (lowercase, numbers, underscores)');
    });

    it.each(['auth_login', 'a', 'login_v2'])('accepts %s for the parameter pattern', (name) => {
      expect(newNameError(name, { namePattern: SNAKE_CASE_PARAM })).toBeNull();
    });

    it('accepts a leading underscore under the domain pattern but not the parameter pattern', () => {
      expect(newNameError('_internal', { namePattern: SNAKE_CASE_DOMAIN })).toBeNull();
      expect(newNameError('_internal', { namePattern: SNAKE_CASE_PARAM })).not.toBeNull();
    });
  });

  describe('file names', () => {
    it.each(['auth.yaml', 'shared_user-v2.yaml', 'events/auth.yaml'])('accepts %s', (name) => {
      expect(newNameError(name, { isFileName: true })).toBeNull();
    });

    it.each(['my file.yaml', 'file{1}.yaml'])('rejects %s', (name) => {
      expect(newNameError(name, { isFileName: true })).toBe('Invalid characters. Use letters, numbers, _, -, .');
    });
  });

  describe('length limit', () => {
    it('accepts 100 chars', () => {
      expect(newNameError('a'.repeat(100))).toBeNull();
    });

    it('rejects 101 chars', () => {
      expect(newNameError('a'.repeat(101))).toBe('Name is too long (max 100 characters)');
    });
  });
});
