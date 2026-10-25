function isPlainObject(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

/** Fills every setting missing from `config` with its default; values already set win, including arrays. */
export function withDefaults<T>(config: T, defaults: T): T {
  if (config === undefined) return defaults;
  if (!isPlainObject(config) || !isPlainObject(defaults)) return config;
  const merged: Record<string, unknown> = { ...config };
  for (const [key, fallback] of Object.entries(defaults)) {
    merged[key] = withDefaults(config[key], fallback);
  }
  return merged as T;
}
