#!/usr/bin/env node
/**
 * Converts existing analytics_gen YAML files into an analytics-studio.json
 * project file that can be imported into AnalyticsGen Studio.
 *
 * Usage:
 *   node scripts/yaml-to-studio.mjs <path-to-analytics_gen.yaml> [-o output.json]
 *
 * Example:
 *   node scripts/yaml-to-studio.mjs ../example/analytics_gen.yaml
 *   node scripts/yaml-to-studio.mjs ../example/analytics_gen.yaml -o my-project.json
 */

import fs from 'fs';
import path from 'path';
import yaml from 'js-yaml';

// ── Helpers ──

function readYaml(filePath) {
  const content = fs.readFileSync(filePath, 'utf-8');
  return yaml.load(content);
}

function resolveRelative(basePath, relativePath) {
  return path.resolve(path.dirname(basePath), relativePath);
}

/** Convert a raw YAML parameter value to Studio ParamDef format */
function convertParam(value) {
  if (value === null || value === undefined) return null; // shared ref
  if (typeof value === 'string') return value; // shorthand
  if (typeof value !== 'object') return String(value);

  const def = {};
  // Find the type — could be 'type' key or legacy type-as-key
  const knownKeys = new Set([
    'type', 'description', 'identifier', 'param_name', 'dart_type',
    'import', 'allowed_values', 'regex', 'min_length', 'max_length',
    'min', 'max', 'meta', 'operations', 'added_in', 'deprecated_in',
  ]);

  let foundType = value.type;
  if (!foundType) {
    for (const k of Object.keys(value)) {
      if (!knownKeys.has(k)) {
        foundType = k;
        break;
      }
    }
  }
  if (foundType) def.type = String(foundType);

  if (value.description != null) def.description = String(value.description);
  if (value.identifier != null) def.identifier = String(value.identifier);
  if (value.param_name != null) def.param_name = String(value.param_name);
  if (value.dart_type != null) def.dart_type = String(value.dart_type);
  if (value.import != null) def.import = String(value.import);
  if (value.allowed_values != null) def.allowed_values = value.allowed_values;
  if (value.regex != null) def.regex = String(value.regex);
  if (value.min_length != null) def.min_length = Number(value.min_length);
  if (value.max_length != null) def.max_length = Number(value.max_length);
  if (value.min != null) def.min = Number(value.min);
  if (value.max != null) def.max = Number(value.max);
  if (value.meta != null) def.meta = value.meta;
  if (value.operations != null) def.operations = value.operations;
  if (value.added_in != null) def.added_in = String(value.added_in);
  if (value.deprecated_in != null) def.deprecated_in = String(value.deprecated_in);

  return def;
}

// ── Parse config ──

function parseConfig(raw) {
  const ag = raw.analytics_gen || raw;

  const inputs = ag.inputs || {};
  const outputs = ag.outputs || {};
  const targets = ag.targets || {};
  const rules = ag.rules || {};
  const naming = ag.naming || {};
  const meta = ag.meta || {};

  return {
    inputs: {
      events: inputs.events || ag.events_path || 'events',
      shared_parameters: inputs.shared_parameters || ag.shared_parameters || [],
      contexts: inputs.contexts || ag.contexts || [],
      imports: inputs.imports || ag.imports || [],
    },
    outputs: {
      dart: outputs.dart || ag.output_path || 'lib/src/analytics/generated',
      ...(outputs.docs || ag.docs_path ? { docs: outputs.docs || ag.docs_path } : {}),
      ...(outputs.exports || ag.exports_path ? { exports: outputs.exports || ag.exports_path } : {}),
    },
    targets: {
      csv: targets.csv ?? ag.generate_csv ?? false,
      json: targets.json ?? ag.generate_json ?? false,
      sql: targets.sql ?? ag.generate_sql ?? false,
      docs: targets.docs ?? ag.generate_docs ?? false,
      plan: targets.plan ?? ag.generate_plan ?? true,
      test_matchers: targets.test_matchers ?? ag.generate_test_matchers ?? false,
    },
    rules: {
      include_event_description: rules.include_event_description ?? ag.include_event_description ?? false,
      strict_event_names: rules.strict_event_names ?? ag.strict_event_names ?? true,
      enforce_centrally_defined_parameters: rules.enforce_centrally_defined_parameters ?? ag.enforce_centrally_defined_parameters ?? false,
      prevent_event_parameter_duplicates: rules.prevent_event_parameter_duplicates ?? ag.prevent_event_parameter_duplicates ?? false,
    },
    naming: {
      casing: naming.casing || 'snake_case',
      enforce_snake_case_domains: naming.enforce_snake_case_domains ?? true,
      enforce_snake_case_parameters: naming.enforce_snake_case_parameters ?? true,
      event_name_template: naming.event_name_template || '{domain}: {event}',
      identifier_template: naming.identifier_template || '{domain}: {event}',
      domain_aliases: naming.domain_aliases || {},
    },
    meta: {
      auto_tracking_creation_date: meta.auto_tracking_creation_date ?? false,
      include_meta_in_parameters: meta.include_meta_in_parameters ?? false,
    },
  };
}

// ── Parse event files ──

function parseEventFile(filePath) {
  const raw = readYaml(filePath);
  if (!raw || typeof raw !== 'object') {
    return { fileName: path.basename(filePath), domains: {} };
  }

  const domains = {};
  for (const [domainName, events] of Object.entries(raw)) {
    if (!events || typeof events !== 'object') continue;
    domains[domainName] = {};

    for (const [eventName, eventData] of Object.entries(events)) {
      if (!eventData || typeof eventData !== 'object') continue;

      const event = {
        description: eventData.description || undefined,
        event_name: eventData.event_name || undefined,
        identifier: eventData.identifier || undefined,
        deprecated: eventData.deprecated || false,
        replacement: eventData.replacement || undefined,
        added_in: eventData.added_in || undefined,
        deprecated_in: eventData.deprecated_in || undefined,
        dual_write_to: eventData.dual_write_to || undefined,
        meta: eventData.meta || undefined,
        parameters: {},
      };

      if (eventData.parameters && typeof eventData.parameters === 'object') {
        for (const [paramName, paramValue] of Object.entries(eventData.parameters)) {
          event.parameters[paramName] = convertParam(paramValue);
        }
      }

      domains[domainName][eventName] = event;
    }
  }

  return { fileName: path.basename(filePath), domains };
}

// ── Parse shared parameter files ──

function parseSharedParamFile(filePath) {
  const raw = readYaml(filePath);
  if (!raw || typeof raw !== 'object') {
    return { fileName: path.basename(filePath), parameters: {} };
  }

  const paramsMap = raw.parameters || raw;
  const parameters = {};

  for (const [name, value] of Object.entries(paramsMap)) {
    parameters[name] = convertParam(value);
  }

  return { fileName: path.basename(filePath), parameters };
}

// ── Parse context files ──

function parseContextFile(filePath) {
  const raw = readYaml(filePath);
  if (!raw || typeof raw !== 'object') {
    return { fileName: path.basename(filePath), contextName: '', properties: {} };
  }

  const keys = Object.keys(raw);
  const contextName = keys[0] || '';
  const propsMap = raw[contextName] || {};
  const properties = {};

  for (const [name, value] of Object.entries(propsMap)) {
    properties[name] = convertParam(value);
  }

  return { fileName: path.basename(filePath), contextName, properties };
}

// ── Discover event files from directory ──

function findYamlFiles(dir) {
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir)
    .filter(f => f.endsWith('.yaml') || f.endsWith('.yml'))
    .map(f => path.join(dir, f));
}

// ── Main ──

function main() {
  const args = process.argv.slice(2);
  if (args.length === 0) {
    console.error('Usage: node scripts/yaml-to-studio.mjs <analytics_gen.yaml> [-o output.json]');
    process.exit(1);
  }

  const configPath = path.resolve(args[0]);
  const outputIndex = args.indexOf('-o');
  const outputPath = outputIndex >= 0 && args[outputIndex + 1]
    ? path.resolve(args[outputIndex + 1])
    : path.join(path.dirname(configPath), 'analytics-studio.json');

  if (!fs.existsSync(configPath)) {
    console.error(`File not found: ${configPath}`);
    process.exit(1);
  }

  console.log(`Reading config: ${configPath}`);
  const rawConfig = readYaml(configPath);
  const config = parseConfig(rawConfig);

  const baseDir = path.dirname(configPath);

  // Event files — scan directory
  const eventsDir = resolveRelative(configPath, config.inputs.events);
  const sharedPaths = config.inputs.shared_parameters.map(p => resolveRelative(configPath, p));
  const contextPaths = config.inputs.contexts.map(p => resolveRelative(configPath, p));

  // Find event YAML files (excluding shared/context files)
  const excludeSet = new Set([...sharedPaths, ...contextPaths].map(p => path.resolve(p)));
  const allYamlInDir = findYamlFiles(eventsDir);
  const eventPaths = allYamlInDir.filter(f => !excludeSet.has(path.resolve(f)));

  console.log(`Found ${eventPaths.length} event file(s), ${sharedPaths.length} shared param file(s), ${contextPaths.length} context file(s)`);

  // Parse
  const eventFiles = eventPaths.map(parseEventFile);
  const sharedParamFiles = sharedPaths.filter(p => fs.existsSync(p)).map(parseSharedParamFile);
  const contextFiles = contextPaths.filter(p => fs.existsSync(p)).map(parseContextFile);

  // Build project
  const project = {
    version: 1,
    activeTab: 'config',
    config,
    eventFiles,
    sharedParamFiles,
    contextFiles,
  };

  fs.writeFileSync(outputPath, JSON.stringify(project, null, 2));
  console.log(`\nGenerated: ${outputPath}`);
  console.log(`\nOpen AnalyticsGen Studio → click "Open Project" → select this file.`);
}

main();
