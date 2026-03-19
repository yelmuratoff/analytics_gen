#!/usr/bin/env node
/**
 * Generates TypeScript interfaces from JSON schemas.
 * Run: npm run generate-types
 */
import { compileFromFile } from 'json-schema-to-typescript';
import { writeFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const SCHEMA_DIR = resolve(__dirname, '../public/schemas');
const OUTPUT = resolve(__dirname, '../src/types/generated.ts');

const opts = {
  bannerComment: '',
  ignoreMinAndMaxItems: true,
  style: { singleQuote: true, semi: true },
  cwd: SCHEMA_DIR,
};

async function generate() {
  const configTypes = await compileFromFile(resolve(SCHEMA_DIR, 'analytics_gen.schema.json'), opts);

  // Parameter schema has additionalProperties with legacy type-as-key syntax
  // which generates index signatures that conflict with typed properties.
  // Read, strip additionalProperties, compile from object instead.
  const { readFileSync } = await import('fs');
  const paramRaw = JSON.parse(readFileSync(resolve(SCHEMA_DIR, 'parameter.schema.json'), 'utf8'));
  delete paramRaw.additionalProperties;
  const { compile } = await import('json-schema-to-typescript');
  const parameterTypes = await compile(paramRaw, 'AnalyticsParameter', opts);

  const output = `// Auto-generated from JSON schemas — do not edit manually.
// Run: npm run generate-types
//
// Source schemas: public/schemas/*.schema.json
// If you change a schema, re-run this script.

// ── Config (analytics_gen.schema.json) ──

${configTypes}

// ── Parameter (parameter.schema.json) ──

${parameterTypes}
`;

  writeFileSync(OUTPUT, output, 'utf8');
  console.log(`✓ Generated types → src/types/generated.ts`);
}

generate().catch((err) => {
  console.error('Failed to generate types:', err);
  process.exit(1);
});
