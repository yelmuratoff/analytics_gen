import 'dart:convert';
import 'dart:io';

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../config/analytics_config.dart';
import '../util/logger.dart';
import '../util/yaml_keys.dart';

/// Generates the AnalyticsGen Studio project file (`analytics-studio.json`)
/// from the analytics YAML configuration.
///
/// Zero field knowledge — reads raw YAML and converts to JSON. Adding new
/// fields to schemas/YAML requires zero changes here.
class StudioGenerator {
  /// Creates a new [StudioGenerator].
  const StudioGenerator({
    required this.config,
    required this.projectRoot,
    required this.configPath,
    this.log = const NoOpLogger(),
  });

  /// Analytics configuration.
  final AnalyticsConfig config;

  /// Project root directory.
  final String projectRoot;

  /// Path to the source `analytics_gen.yaml` (relative to [projectRoot]).
  final String configPath;

  /// The logger to use.
  final Logger log;

  /// Generates the studio project file at [outputPath] (or
  /// `config.outputs.studioPath` when omitted).
  Future<File> generate({String? outputPath}) async {
    final resolvedOutput = outputPath ?? config.outputs.studioPath;
    final eventsDir = p.join(projectRoot, config.inputs.eventsPath);
    final sharedPaths = config.inputs.sharedParameters
        .map((sp) => p.join(projectRoot, sp))
        .toSet();
    final contextPaths =
        config.inputs.contexts.map((cp) => p.join(projectRoot, cp)).toSet();

    final eventFiles = _readEventFiles(eventsDir, sharedPaths, contextPaths);
    final sharedParamFiles = _readSharedParamFiles(sharedPaths);
    final contextFiles = _readContextFiles(contextPaths);

    log.info(
      'Studio export: ${eventFiles.length} event file(s), '
      '${sharedParamFiles.length} shared param file(s), '
      '${contextFiles.length} context file(s)',
    );

    final studioJson = <String, dynamic>{
      'version': 1,
      'activeTab': 'config',
      'config': _readConfigYaml(p.join(projectRoot, configPath)),
      'eventFiles': eventFiles,
      'sharedParamFiles': sharedParamFiles,
      'contextFiles': contextFiles,
    };

    final outputFile = File(p.join(projectRoot, resolvedOutput));
    await outputFile.parent.create(recursive: true);
    await outputFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(studioJson),
    );

    log.info('Studio project written to ${outputFile.path}');
    return outputFile;
  }

  // ── Raw YAML readers (zero field knowledge) ──

  /// Reads `analytics_gen.yaml`, unwraps the root key, strips flat aliases.
  /// Real sections (`inputs`, `outputs`, `targets`, …) are always Maps; flat
  /// aliases are scalar/array values, so filtering by type works without
  /// hardcoding any names.
  Map<String, dynamic> _readConfigYaml(String path) {
    final file = File(path);
    if (!file.existsSync()) return <String, dynamic>{};

    final parsed = loadYaml(file.readAsStringSync());
    if (parsed is! YamlMap) return <String, dynamic>{};

    final inner = parsed[YamlKeys.analyticsGen];
    if (inner is! YamlMap) return <String, dynamic>{};

    final json = _yamlToJson(inner) as Map<String, dynamic>;
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
    if (!dir.existsSync()) return <Map<String, dynamic>>[];

    final excluded = {...sharedPaths, ...contextPaths}.map(p.normalize).toSet();

    final files = Glob('**.{yaml,yml}')
        .listSync(root: eventsDir)
        .whereType<File>()
        .where((f) => !excluded.contains(p.normalize(f.path)))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    return files
        .map(
          (file) => _readYamlFileAs(
            file,
            (parsed) {
              final domains = <String, dynamic>{};
              for (final e in parsed.entries) {
                final events = e.value;
                if (events is! YamlMap) continue;
                domains[e.key.toString()] = <String, dynamic>{
                  for (final ev in events.entries)
                    if (ev.value is YamlMap)
                      ev.key.toString(): _yamlToJson(ev.value),
                };
              }
              return {'fileName': p.basename(file.path), 'domains': domains};
            },
            fallback: {
              'fileName': p.basename(file.path),
              'domains': <String, dynamic>{},
            },
          ),
        )
        .toList();
  }

  /// Reads shared parameter files.
  /// Structure: {parameters: {name: def}} → wraps as {fileName, parameters}.
  List<Map<String, dynamic>> _readSharedParamFiles(Set<String> paths) {
    return paths
        .map(
          (filePath) => _readYamlFileAs(
            File(filePath),
            (parsed) {
              final node = parsed[YamlKeys.parameters] ?? parsed;
              return {
                'fileName': p.basename(filePath),
                'parameters':
                    node is YamlMap ? _yamlToJson(node) : <String, dynamic>{},
              };
            },
            fallback: {
              'fileName': p.basename(filePath),
              'parameters': <String, dynamic>{},
            },
          ),
        )
        .toList();
  }

  /// Reads context files.
  /// Structure: {context_name: {prop: def}} → wraps as
  /// {fileName, contextName, properties}.
  List<Map<String, dynamic>> _readContextFiles(Set<String> paths) {
    return paths
        .map(
          (filePath) => _readYamlFileAs(
            File(filePath),
            (parsed) {
              final name = parsed.keys.first.toString();
              final props = parsed[name];
              return {
                'fileName': p.basename(filePath),
                'contextName': name,
                'properties':
                    props is YamlMap ? _yamlToJson(props) : <String, dynamic>{},
              };
            },
            fallback: {
              'fileName': p.basename(filePath),
              'contextName': '',
              'properties': <String, dynamic>{},
            },
          ),
        )
        .toList();
  }

  // ── Helpers ──

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
      return <dynamic>[for (final item in value) _yamlToJson(item)];
    }
    return value;
  }
}
