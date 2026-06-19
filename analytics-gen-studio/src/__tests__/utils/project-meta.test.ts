import { describe, it, expect } from 'vitest';
import {
  cyrb53,
  computeRevision,
  newProjectId,
  slugify,
  deriveJsonName,
  deriveZipName,
  type RevisionContent,
} from '../../utils/project-meta.ts';

const emptyContent: RevisionContent = {
  config: {} as RevisionContent['config'],
  eventFiles: [],
  sharedParamFiles: [],
  contextFiles: [],
};

describe('cyrb53', () => {
  it('produces stable reference values (locks Dart parity)', () => {
    expect(cyrb53('hello')).toBe(4625896200565286);
    expect(cyrb53('')).toBe(3338908027751811);
  });

  it('differs for different input', () => {
    expect(cyrb53('a')).not.toBe(cyrb53('b'));
  });
});

describe('computeRevision', () => {
  it('returns a stable reference revision for empty content', () => {
    expect(computeRevision(emptyContent)).toBe('07f86068ecf134');
  });

  it('is identical for the same content', () => {
    const content: RevisionContent = {
      ...emptyContent,
      eventFiles: [{ fileName: 'auth.yaml', domains: {} }],
    };
    expect(computeRevision(content)).toBe(computeRevision({ ...content }));
  });

  it('ignores object key ordering', () => {
    const a = { config: { a: 1, b: 2 } } as unknown as RevisionContent;
    const b = { config: { b: 2, a: 1 } } as unknown as RevisionContent;
    expect(computeRevision(a)).toBe(computeRevision(b));
  });

  it('changes when content changes', () => {
    const before = computeRevision(emptyContent);
    const after = computeRevision({
      ...emptyContent,
      eventFiles: [{ fileName: 'a.yaml', domains: { auth: {} } }],
    });
    expect(after).not.toBe(before);
  });
});

describe('newProjectId', () => {
  it('generates unique non-empty ids', () => {
    const a = newProjectId();
    const b = newProjectId();
    expect(a).toBeTruthy();
    expect(a).not.toBe(b);
  });
});

describe('slugify', () => {
  it('lowercases and replaces unsafe characters with dashes', () => {
    expect(slugify('My Analytics Project!')).toBe('my-analytics-project');
  });

  it('trims leading and trailing dashes', () => {
    expect(slugify('  --Hello--  ')).toBe('hello');
  });

  it('returns empty string for non-alphanumeric input', () => {
    expect(slugify('   ')).toBe('');
    expect(slugify('***')).toBe('');
  });
});

describe('deriveJsonName / deriveZipName', () => {
  it('falls back to defaults when no project name', () => {
    expect(deriveJsonName('')).toBe('analytics-studio.json');
    expect(deriveZipName('')).toBe('analytics-gen-config.zip');
  });

  it('derives from the project name', () => {
    expect(deriveJsonName('Checkout Funnel')).toBe('checkout-funnel.json');
    expect(deriveZipName('Checkout Funnel')).toBe('checkout-funnel.zip');
  });

  it('appends a short revision suffix when unique is requested', () => {
    expect(deriveJsonName('App', { unique: true, revision: 'abcdef1234567' }))
      .toBe('app-abcdef12.json');
    expect(deriveZipName('App', { unique: true, revision: 'abcdef1234567' }))
      .toBe('app-abcdef12.zip');
  });

  it('omits the suffix when unique is false', () => {
    expect(deriveJsonName('App', { unique: false, revision: 'abcdef1234567' }))
      .toBe('app.json');
  });
});
