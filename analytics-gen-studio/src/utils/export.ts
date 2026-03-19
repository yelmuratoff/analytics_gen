import JSZip from 'jszip';
import { saveAs } from 'file-saver';
import type { StudioState } from '../types/index.ts';
import {
  generateConfigYaml,
  generateEventFileYaml,
  generateSharedParamFileYaml,
  generateContextFileYaml,
} from './yaml-generator.ts';

export function exportSingleFile(content: string, fileName: string) {
  const blob = new Blob([content], { type: 'text/yaml;charset=utf-8' });
  saveAs(blob, fileName);
}

export function exportAllAsZip(state: StudioState) {
  const zip = new JSZip();

  // Config
  zip.file('analytics_gen.yaml', generateConfigYaml(state.config));

  // Event files
  for (const file of state.eventFiles) {
    zip.file(file.fileName, generateEventFileYaml(file));
  }

  // Shared param files
  for (const file of state.sharedParamFiles) {
    zip.file(file.fileName, generateSharedParamFileYaml(file));
  }

  // Context files
  for (const file of state.contextFiles) {
    zip.file(file.fileName, generateContextFileYaml(file));
  }

  zip.generateAsync({ type: 'blob' }).then((blob) => {
    saveAs(blob, 'analytics-gen-config.zip');
  });
}

export function saveProject(state: StudioState) {
  const projectData = {
    version: 1,
    activeTab: state.activeTab,
    config: state.config,
    eventFiles: state.eventFiles,
    sharedParamFiles: state.sharedParamFiles,
    contextFiles: state.contextFiles,
  };
  const blob = new Blob([JSON.stringify(projectData, null, 2)], { type: 'application/json' });
  saveAs(blob, 'analytics-studio.json');
}

export function loadProjectFile(file: File): Promise<Partial<StudioState>> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const data = JSON.parse(e.target?.result as string);
        if (!data.version || !data.config) {
          reject(new Error('Invalid project file format'));
          return;
        }
        resolve(data);
      } catch {
        reject(new Error('Failed to parse project file'));
      }
    };
    reader.onerror = () => reject(new Error('Failed to read file'));
    reader.readAsText(file);
  });
}

export function copyToClipboard(text: string): Promise<void> {
  return navigator.clipboard.writeText(text);
}
