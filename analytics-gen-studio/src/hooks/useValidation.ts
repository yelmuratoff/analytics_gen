import { useMemo } from 'react';
import { useStore } from '../state/store.ts';
import type { ValidationError } from '../types/index.ts';

export function useValidation(): ValidationError[] {
  const config = useStore((s) => s.config);
  const eventFiles = useStore((s) => s.eventFiles);
  const sharedParamFiles = useStore((s) => s.sharedParamFiles);
  const contextFiles = useStore((s) => s.contextFiles);

  return useMemo(() => {
    const errors: ValidationError[] = [];

    // Config validation
    if (!config.outputs.dart) {
      errors.push({ path: 'config.outputs.dart', message: 'Dart output path is required', tab: 'config' });
    }

    // Event file validation
    const fileNames = new Set<string>();
    for (const file of eventFiles) {
      if (fileNames.has(file.fileName)) {
        errors.push({ path: `events.${file.fileName}`, message: `Duplicate file name: ${file.fileName}`, tab: 'events' });
      }
      fileNames.add(file.fileName);

      for (const [domainName, events] of Object.entries(file.domains)) {
        if (config.naming.enforce_snake_case_domains && !/^[a-z0-9_]+$/.test(domainName)) {
          errors.push({ path: `events.${file.fileName}.${domainName}`, message: `Domain "${domainName}" must be snake_case`, tab: 'events' });
        }
        for (const [eventName, event] of Object.entries(events)) {
          for (const [paramName, paramVal] of Object.entries(event.parameters)) {
            if (paramVal !== null && typeof paramVal === 'object') {
              if (paramVal.dart_type && paramVal.allowed_values && paramVal.allowed_values.length > 0) {
                errors.push({
                  path: `events.${file.fileName}.${domainName}.${eventName}.${paramName}`,
                  message: `Parameter "${paramName}": dart_type and allowed_values are mutually exclusive`,
                  tab: 'events',
                });
              }
            }
          }
        }
      }
    }

    // Shared param file validation
    const spFileNames = new Set<string>();
    for (const file of sharedParamFiles) {
      if (spFileNames.has(file.fileName)) {
        errors.push({ path: `shared.${file.fileName}`, message: `Duplicate file name: ${file.fileName}`, tab: 'shared' });
      }
      spFileNames.add(file.fileName);
    }

    // Context file validation
    const ctxFileNames = new Set<string>();
    for (const file of contextFiles) {
      if (ctxFileNames.has(file.fileName)) {
        errors.push({ path: `contexts.${file.fileName}`, message: `Duplicate file name: ${file.fileName}`, tab: 'contexts' });
      }
      ctxFileNames.add(file.fileName);
    }

    return errors;
  }, [config, eventFiles, sharedParamFiles, contextFiles]);
}
