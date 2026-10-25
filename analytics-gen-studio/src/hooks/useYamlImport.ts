import { useCallback } from 'react';
import { useStore } from '../state/store.ts';
import {
  importYamlString,
  tabForImport,
  type ImportFailure,
  type ImportSchemaHints,
  type ImportSummary,
  type YamlImportResult,
} from '../utils/yaml-importer.ts';
import type { TabId } from '../types/index.ts';

/** Imports YAML files into the project, opens the tab of the last imported file, and reports what was skipped. */
export function useYamlImport(hints: ImportSchemaHints): (files: File[]) => Promise<ImportSummary> {
  const importEventFile = useStore((s) => s.importEventFile);
  const importSharedParamFile = useStore((s) => s.importSharedParamFile);
  const importContextFile = useStore((s) => s.importContextFile);
  const mergeConfig = useStore((s) => s.mergeConfig);
  const setActiveTab = useStore((s) => s.setActiveTab);

  return useCallback(async (files: File[]) => {
    const failures: ImportFailure[] = [];
    const ignoredKeys: string[] = [];
    let imported = 0;
    let lastTab: TabId | null = null;

    for (const file of files) {
      let result: YamlImportResult | null;
      try {
        result = importYamlString(await file.text(), file.name, hints);
      } catch (err) {
        failures.push({ fileName: file.name, reason: err instanceof Error ? err.message.split('\n')[0] : 'invalid YAML' });
        continue;
      }
      if (!result) {
        failures.push({ fileName: file.name, reason: 'unknown file type' });
        continue;
      }
      if (result.eventFile) importEventFile(result.eventFile);
      if (result.sharedFile) importSharedParamFile(result.sharedFile);
      if (result.contextFile) importContextFile(result.contextFile);
      if (result.config) mergeConfig(result.config);
      ignoredKeys.push(...(result.ignoredKeys ?? []));
      lastTab = tabForImport(result.type);
      imported++;
    }

    if (lastTab) setActiveTab(lastTab);
    return { imported, failures, ignoredKeys };
  }, [hints, importEventFile, importSharedParamFile, importContextFile, mergeConfig, setActiveTab]);
}
