import { useState, useEffect, useRef } from 'react';
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

function computeYaml(activeTab: string, config: unknown, eventFiles: unknown[], sharedParamFiles: unknown[], contextFiles: unknown[]): YamlFile[] {
  switch (activeTab) {
    case 'config':
      return [{ fileName: 'analytics_gen.yaml', content: generateConfigYaml(config as Parameters<typeof generateConfigYaml>[0]) }];
    case 'events':
      return (eventFiles as Parameters<typeof generateEventFileYaml>[0][]).map((f) => ({
        fileName: f.fileName,
        content: generateEventFileYaml(f),
      }));
    case 'shared':
      return (sharedParamFiles as Parameters<typeof generateSharedParamFileYaml>[0][]).map((f) => ({
        fileName: f.fileName,
        content: generateSharedParamFileYaml(f),
      }));
    case 'contexts':
      return (contextFiles as Parameters<typeof generateContextFileYaml>[0][]).map((f) => ({
        fileName: f.fileName,
        content: generateContextFileYaml(f),
      }));
    default:
      return [];
  }
}

/** Debounced YAML preview — avoids blocking the main thread on every keystroke */
export function useYamlPreview(): YamlFile[] {
  const activeTab = useStore((s) => s.activeTab);
  const config = useStore((s) => s.config);
  const eventFiles = useStore((s) => s.eventFiles);
  const sharedParamFiles = useStore((s) => s.sharedParamFiles);
  const contextFiles = useStore((s) => s.contextFiles);

  const [result, setResult] = useState(() => computeYaml(activeTab, config, eventFiles, sharedParamFiles, contextFiles));
  const timerRef = useRef<ReturnType<typeof setTimeout>>(undefined);

  useEffect(() => {
    clearTimeout(timerRef.current);
    timerRef.current = setTimeout(() => {
      setResult(computeYaml(activeTab, config, eventFiles, sharedParamFiles, contextFiles));
    }, 150);
    return () => clearTimeout(timerRef.current);
  }, [activeTab, config, eventFiles, sharedParamFiles, contextFiles]);

  return result;
}
