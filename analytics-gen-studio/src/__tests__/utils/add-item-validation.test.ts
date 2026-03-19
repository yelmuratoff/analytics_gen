import { describe, it, expect } from 'vitest';

// Test the validation logic from AddItemDialog directly
// (extracted here since it's pure logic)

const YAML_UNSAFE = /[:{}\[\]&*?|><!%@`#,'"\\]/;
const VALID_YAML_KEY = /^[a-zA-Z_][a-zA-Z0-9_./-]*$/;

function validate(input: string, opts: { validateSnakeCase?: boolean; isFileName?: boolean; existingNames?: string[] } = {}): string | null {
  if (!input) return 'Name cannot be empty';
  if (opts.existingNames?.includes(input)) return 'Name already exists';

  if (opts.isFileName) {
    if (!/^[a-zA-Z0-9_.\-/]+$/.test(input)) return 'Invalid characters';
  } else {
    if (YAML_UNSAFE.test(input)) return 'Contains YAML-unsafe characters';
    if (!VALID_YAML_KEY.test(input)) return 'Invalid YAML key';
    if (opts.validateSnakeCase && !/^[a-z][a-z0-9_]*$/.test(input)) return 'Must be snake_case';
  }

  if (input.length > 100) return 'Too long';
  return null;
}

describe('AddItemDialog validation', () => {
  describe('empty input', () => {
    it('rejects empty string', () => {
      expect(validate('')).toBe('Name cannot be empty');
    });
  });

  describe('duplicate names', () => {
    it('rejects existing name', () => {
      expect(validate('auth', { existingNames: ['auth', 'user'] })).toBe('Name already exists');
    });

    it('accepts new name', () => {
      expect(validate('purchase', { existingNames: ['auth'] })).toBeNull();
    });
  });

  describe('YAML key validation', () => {
    it.each([
      ':', '{', '}', '[', ']', '&', '*', '?', '|', '>', '<', '!', '%', '@', '`', '#', ',', "'", '"', '\\',
    ])('rejects YAML-unsafe char: %s', (char) => {
      expect(validate(`test${char}name`)).toBe('Contains YAML-unsafe characters');
    });

    it('rejects key starting with number', () => {
      expect(validate('123abc')).toBe('Invalid YAML key');
    });

    it('accepts key starting with letter', () => {
      expect(validate('auth_login')).toBeNull();
    });

    it('accepts key starting with underscore', () => {
      expect(validate('_internal')).toBeNull();
    });

    it('accepts dots and slashes in key', () => {
      expect(validate('path/to.file')).toBeNull();
    });
  });

  describe('snake_case validation', () => {
    it('rejects uppercase', () => {
      expect(validate('MyDomain', { validateSnakeCase: true })).toBe('Must be snake_case');
    });

    it('rejects starting with number', () => {
      expect(validate('1abc', { validateSnakeCase: true })).not.toBeNull();
    });

    it('accepts valid snake_case', () => {
      expect(validate('auth_login', { validateSnakeCase: true })).toBeNull();
    });

    it('accepts single letter', () => {
      expect(validate('a', { validateSnakeCase: true })).toBeNull();
    });

    it('accepts underscores and numbers', () => {
      expect(validate('login_v2', { validateSnakeCase: true })).toBeNull();
    });
  });

  describe('fileName validation', () => {
    it('accepts alphanumeric with dots', () => {
      expect(validate('auth.yaml', { isFileName: true })).toBeNull();
    });

    it('accepts dashes and underscores', () => {
      expect(validate('shared_user-v2.yaml', { isFileName: true })).toBeNull();
    });

    it('accepts path with slashes', () => {
      expect(validate('events/auth.yaml', { isFileName: true })).toBeNull();
    });

    it('rejects spaces', () => {
      expect(validate('my file.yaml', { isFileName: true })).toBe('Invalid characters');
    });

    it('rejects YAML special chars', () => {
      expect(validate('file{1}.yaml', { isFileName: true })).toBe('Invalid characters');
    });
  });

  describe('length limit', () => {
    it('accepts 100 chars', () => {
      expect(validate('a'.repeat(100))).toBeNull();
    });

    it('rejects 101 chars', () => {
      expect(validate('a'.repeat(101))).toBe('Too long');
    });
  });
});
