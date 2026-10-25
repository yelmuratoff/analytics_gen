/** Appends `.yaml` unless the name already ends with it. */
export function withYamlExtension(name: string): string {
  return name.endsWith('.yaml') ? name : `${name}.yaml`;
}
