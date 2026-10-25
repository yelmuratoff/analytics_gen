import { useState, useEffect, useRef } from 'react';
import { useStore } from '../state/store.ts';
import { yamlFilesFor, type YamlFile } from '../utils/yaml-generator.ts';

/** Debounced YAML preview — avoids blocking the main thread on every keystroke */
export function useYamlPreview(): YamlFile[] {
  const activeTab = useStore((s) => s.activeTab);
  const config = useStore((s) => s.config);
  const eventFiles = useStore((s) => s.eventFiles);
  const sharedParamFiles = useStore((s) => s.sharedParamFiles);
  const contextFiles = useStore((s) => s.contextFiles);

  const [result, setResult] = useState(() => yamlFilesFor(activeTab, { config, eventFiles, sharedParamFiles, contextFiles }));
  const timerRef = useRef<ReturnType<typeof setTimeout>>(undefined);

  useEffect(() => {
    clearTimeout(timerRef.current);
    timerRef.current = setTimeout(() => {
      setResult(yamlFilesFor(activeTab, { config, eventFiles, sharedParamFiles, contextFiles }));
    }, 150);
    return () => clearTimeout(timerRef.current);
  }, [activeTab, config, eventFiles, sharedParamFiles, contextFiles]);

  return result;
}
