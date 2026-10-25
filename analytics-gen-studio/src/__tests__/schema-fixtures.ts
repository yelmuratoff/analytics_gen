import type { RJSFSchema } from '@rjsf/utils';

const schemaModules = import.meta.glob<{ default: RJSFSchema }>('../../../schema/*.json', { eager: true });

/** Returns a canonical schema from the repository's schema/ directory, as the Studio loader receives it. */
export function canonicalSchema(name: string): RJSFSchema | undefined {
  const entry = Object.entries(schemaModules).find(([path]) => path.endsWith(`/${name}`));
  return entry?.[1].default;
}
