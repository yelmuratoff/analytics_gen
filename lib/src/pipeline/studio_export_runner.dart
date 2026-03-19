import 'dart:convert';
import 'dart:io';

import 'package:analytics_gen/src/config/config_parser.dart';
import 'package:analytics_gen/src/util/logger.dart';
import 'package:args/args.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../cli/arguments.dart';
import '../config/config_loader.dart';

/// Exports the analytics YAML configuration as an `analytics-studio.json`
/// importable by AnalyticsGen Studio.
///
/// Zero field knowledge — reads raw YAML and converts to JSON.
/// Adding new fields to schemas/YAML requires zero changes here.
class StudioExportRunner {
  /// Creates a new [StudioExportRunner].
  StudioExportRunner({
    ArgParser? parser,
    ConfigParser? configParser,
  })  : _parser = parser ?? _createParser(),
        _configParser = configParser;

  final ArgParser _parser;
  final ConfigParser? _configParser;

  static ArgParser _createParser() {
    final base = createArgParser();
    base.addOption(
      'output',
      abbr: 'o',
      help: 'Output path for the studio project file.',
      defaultsTo: 'analytics-studio.json',
    );
    return base;
  }

  /// Runs the export.
  Future<void> run(List<String> arguments) async {
    Logger? logger;
    try {
      final results = _parser.parse(arguments);
      final verbose = results['verbose'] as bool;
      logger = ConsoleLogger(verbose: verbose);

      if (results['help'] as bool) {
        _printUsage(logger);
        return;
      }

      final projectRoot = Directory.current.path;
      final configPath = results['config'] as String;
      final outputPath = results['output'] as String;

      // Parse config only to resolve file paths
      final config = await loadAnalyticsConfig(
        projectRoot,
        configPath,
        logger: logger,
        parser: _configParser,
      );

      logger.info('Exporting to AnalyticsGen Studio format...');

      final eventsDir = p.join(projectRoot, config.inputs.eventsPath);
      final sharedPaths = config.inputs.sharedParameters
          .map((sp) => p.join(projectRoot, sp))
          .toSet();
      final contextPaths =
          config.inputs.contexts.map((cp) => p.join(projectRoot, cp)).toSet();

      final eventFiles = _readEventFiles(eventsDir, sharedPaths, contextPaths);
      final sharedParamFiles = _readSharedParamFiles(sharedPaths);
      final contextFiles = _readContextFiles(contextPaths);

      logger.info(
        'Found ${eventFiles.length} event file(s), '
        '${sharedParamFiles.length} shared param file(s), '
        '${contextFiles.length} context file(s)',
      );

      final studioJson = {
        'version': 1,
        'activeTab': 'config',
        'config': _readConfigYaml(p.join(projectRoot, configPath)),
        'eventFiles': eventFiles,
        'sharedParamFiles': sharedParamFiles,
        'contextFiles': contextFiles,
      };

      final outputFile = File(p.join(projectRoot, outputPath));
      await outputFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(studioJson),
      );

      logger.info('');
      logger.info('Exported: ${outputFile.path}');
      logger.info(
        'Open AnalyticsGen Studio → "Open Project" → select this file.',
      );
    } catch (e) {
      (logger ?? const ConsoleLogger()).error('Error: $e');
      exit(1);
    }
  }

  void _printUsage(Logger logger) {
    logger.info('AnalyticsGen Studio Export');
    logger.info('');
    logger.info('Usage: dart run analytics_gen:studio_export [options]');
    logger.info('');
    logger.info(_parser.usage);
  }

  // ── Raw YAML readers (zero field knowledge) ──

  /// Reads analytics_gen.yaml → unwraps root → strips flat aliases automatically.
  /// Flat aliases are detected as non-Map values at the root level of `analytics_gen:`.
  /// All real sections (inputs, outputs, targets, rules, naming, meta, etc.)
  /// are always Map objects, so this works regardless of which aliases exist.
  Map<String, dynamic> _readConfigYaml(String path) {
    final file = File(path);
    if (!file.existsSync()) return {};

    final parsed = loadYaml(file.readAsStringSync());
    if (parsed is! YamlMap) return {};

    final inner = parsed['analytics_gen'];
    if (inner is! YamlMap) return {};

    final json = _yamlToJson(inner) as Map<String, dynamic>;

    // Strip flat aliases: at the root of analytics_gen, real sections are
    // always Maps. Everything else (strings, bools, arrays) is a flat alias.
    json.removeWhere((_, value) => value is! Map);

    return json;
  }

  /// Reads event YAML files from the events directory.
  /// Structure: domain → event → {fields} → wraps as {fileName, domains}.
  List<Map<String, dynamic>> _readEventFiles(
    String eventsDir,
    Set<String> sharedPaths,
    Set<String> contextPaths,
  ) {
    final dir = Directory(eventsDir);
    if (!dir.existsSync()) return [];

    final excluded = {...sharedPaths, ...contextPaths}.map(p.normalize).toSet();

    final files = Glob('**.{yaml,yml}')
        .listSync(root: eventsDir)
        .whereType<File>()
        .where((f) => !excluded.contains(p.normalize(f.path)))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    return files
        .map((file) => _readYamlFileAs(
              file,
              (parsed) {
                final domains = <String, dynamic>{};
                for (final e in parsed.entries) {
                  final events = e.value;
                  if (events is! YamlMap) continue;
                  domains[e.key.toString()] = {
                    for (final ev in events.entries)
                      if (ev.value is YamlMap)
                        ev.key.toString(): _yamlToJson(ev.value),
                  };
                }
                return {'fileName': p.basename(file.path), 'domains': domains};
              },
              fallback: {
                'fileName': p.basename(file.path),
                'domains': <String, dynamic>{}
              },
            ))
        .toList();
  }

  /// Reads shared parameter files.
  /// Structure: {parameters: {name: def}} → wraps as {fileName, parameters}.
  List<Map<String, dynamic>> _readSharedParamFiles(Set<String> paths) {
    return paths
        .map((filePath) => _readYamlFileAs(
              File(filePath),
              (parsed) {
                final node = parsed['parameters'] ?? parsed;
                return {
                  'fileName': p.basename(filePath),
                  'parameters':
                      node is YamlMap ? _yamlToJson(node) : <String, dynamic>{},
                };
              },
              fallback: {
                'fileName': p.basename(filePath),
                'parameters': <String, dynamic>{}
              },
            ))
        .toList();
  }

  /// Reads context files.
  /// Structure: {context_name: {prop: def}} → wraps as {fileName, contextName, properties}.
  List<Map<String, dynamic>> _readContextFiles(Set<String> paths) {
    return paths
        .map((filePath) => _readYamlFileAs(
              File(filePath),
              (parsed) {
                final name = parsed.keys.first.toString();
                final props = parsed[name];
                return {
                  'fileName': p.basename(filePath),
                  'contextName': name,
                  'properties': props is YamlMap
                      ? _yamlToJson(props)
                      : <String, dynamic>{},
                };
              },
              fallback: {
                'fileName': p.basename(filePath),
                'contextName': '',
                'properties': <String, dynamic>{}
              },
            ))
        .toList();
  }

  // ── Helpers ──

  /// Reads a YAML file and transforms it, or returns fallback.
  Map<String, dynamic> _readYamlFileAs(
    File file,
    Map<String, dynamic> Function(YamlMap) transform, {
    required Map<String, dynamic> fallback,
  }) {
    if (!file.existsSync()) return fallback;
    try {
      final parsed = loadYaml(file.readAsStringSync());
      if (parsed is! YamlMap || parsed.isEmpty) return fallback;
      return transform(parsed);
    } catch (_) {
      return fallback;
    }
  }

  /// Recursively converts any YAML node to JSON-compatible Dart object.
  /// Knows nothing about schemas, fields, or structure.
  static dynamic _yamlToJson(dynamic value) {
    if (value is YamlMap) {
      return <String, dynamic>{
        for (final e in value.entries) e.key.toString(): _yamlToJson(e.value),
      };
    }
    if (value is YamlList) {
      return [for (final item in value) _yamlToJson(item)];
    }
    return value;
  }
}
