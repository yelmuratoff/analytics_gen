import { useMemo } from 'react';
import { useStore } from '../state/store.ts';
import {
  generateConfigYaml,
  generateEventFileYaml,
  generateSharedParamFileYaml,
  generateContextFileYaml,
} from '../utils/yaml-generator.ts';

export interface YamlFile {
  fileName: string;
  content: string;
}

export function useYamlPreview(): YamlFile[] {
  const activeTab = useStore((s) => s.activeTab);
  const config = useStore((s) => s.config);
  const eventFiles = useStore((s) => s.eventFiles);
  const sharedParamFiles = useStore((s) => s.sharedParamFiles);
  const contextFiles = useStore((s) => s.contextFiles);

  return useMemo(() => {
    switch (activeTab) {
      case 'config':
        return [{ fileName: 'analytics_gen.yaml', content: generateConfigYaml(config) }];
      case 'events':
        return eventFiles.map((f) => ({
          fileName: f.fileName,
          content: generateEventFileYaml(f),
        }));
      case 'shared':
        return sharedParamFiles.map((f) => ({
          fileName: f.fileName,
          content: generateSharedParamFileYaml(f),
        }));
      case 'contexts':
        return contextFiles.map((f) => ({
          fileName: f.fileName,
          content: generateContextFileYaml(f),
        }));
    }
  }, [activeTab, config, eventFiles, sharedParamFiles, contextFiles]);
}
