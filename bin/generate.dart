import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/generator/code_generator.dart';
import 'package:analytics_gen/src/generator/docs_generator.dart';
import 'package:analytics_gen/src/generator/export_generator.dart';
import 'package:analytics_gen/src/parser/yaml_parser.dart';

ArgParser createArgParser() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show usage information',
    )
    ..addFlag(
      'watch',
      abbr: 'w',
      negatable: false,
      help: 'Watch for changes and regenerate automatically',
    )
    ..addFlag(
      'code',
      negatable: true,
      defaultsTo: true,
      help: 'Generate analytics code',
    )
    ..addFlag(
      'docs',
      negatable: true,
      help: 'Generate documentation',
    )
    ..addFlag(
      'exports',
      negatable: true,
      help: 'Generate export files (CSV, JSON, SQL)',
    )
    ..addOption(
      'config',
      abbr: 'c',
      help: 'Path to config file',
      defaultsTo: 'analytics_gen.yaml',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: true,
      defaultsTo: true,
      help: 'Show detailed generation logs',
    )
    ..addFlag(
      'validate-only',
      negatable: false,
      help: 'Validate YAML tracking plan only (no files written)',
    );
}

Future<void> main(List<String> arguments) async {
  final parser = createArgParser();

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      _printUsage(parser);
      return;
    }

    final projectRoot = Directory.current.path;
    final configPath = results['config'] as String;
    final config = await _loadConfig(projectRoot, configPath);

    final generateCode = results['code'] as bool;
    final generateDocs = resolveDocsFlag(results, config);
    final generateExports = resolveExportsFlag(results, config);
    final verbose = results['verbose'] as bool;
    final watch = results['watch'] as bool;
    final validateOnly = results['validate-only'] as bool;

    if (validateOnly && watch) {
      print('Error: --validate-only cannot be used together with --watch.');
      exit(1);
    }

    if (validateOnly) {
      await _validateTrackingPlan(
        projectRoot,
        config,
        verbose: verbose,
      );
      return;
    }

    if (watch) {
      await _watchMode(
        projectRoot,
        config,
        generateCode: generateCode,
        generateDocs: generateDocs,
        generateExports: generateExports,
        verbose: verbose,
      );
    } else {
      await _generate(
        projectRoot,
        config,
        generateCode: generateCode,
        generateDocs: generateDocs,
        generateExports: generateExports,
        verbose: verbose,
      );
    }
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}

/// Prints usage information
void _printUsage(ArgParser parser) {
  print('Analytics Gen - Code generator for type-safe analytics events');
  print('');
  print('Usage: dart run analytics_gen:generate [options]');
  print('');
  print('Options:');
  print(parser.usage);
  print('');
  print('Examples:');
  print('  # Generate code only');
  print('  dart run analytics_gen:generate');
  print('');
  print('  # Generate code and documentation');
  print('  dart run analytics_gen:generate --docs');
  print('');
  print('  # Generate everything');
  print('  dart run analytics_gen:generate --docs --exports');
  print('');
  print('  # Watch mode');
  print('  dart run analytics_gen:generate --watch');
  print('');
  print('  # Validate YAML only (no files written)');
  print('  dart run analytics_gen:generate --validate-only');
}

/// Determines whether docs should be generated based on CLI flags and config.
bool resolveDocsFlag(ArgResults results, AnalyticsConfig config) {
  if (results.wasParsed('docs')) {
    return results['docs'] as bool;
  }
  return config.generateDocs;
}

/// Determines whether exports should be generated based on CLI flags/config.
bool resolveExportsFlag(ArgResults results, AnalyticsConfig config) {
  if (results.wasParsed('exports')) {
    return results['exports'] as bool;
  }
  return config.generateCsv || config.generateJson || config.generateSql;
}

/// Loads configuration from file or returns default
Future<AnalyticsConfig> _loadConfig(
  String projectRoot,
  String configPath,
) async {
  final configFile = File(path.join(projectRoot, configPath));

  if (!configFile.existsSync()) {
    print('No config file found at $configPath, using defaults');
    print('');
    print('Tip: Create an analytics_gen.yaml file to customize paths:');
    print('');
    print('analytics_gen:');
    print('  events_path: events');
    print('  output_path: src/analytics/generated');
    print('  docs_path: docs/analytics_events.md');
    print('  exports_path: assets/generated');
    print('  generate_docs: true');
    print('  generate_csv: true');
    print('  generate_json: true');
    print('  generate_sql: true');
    print('');
    return AnalyticsConfig.defaultConfig;
  }

  final content = await configFile.readAsString();
  final yaml = loadYaml(content) as Map;
  return AnalyticsConfig.fromYaml(yaml);
}

/// Validates YAML tracking plan without writing any files.
Future<void> _validateTrackingPlan(
  String projectRoot,
  AnalyticsConfig config, {
  required bool verbose,
}) async {
  print('╔════════════════════════════════════════════════╗');
  print('║   Analytics Gen - Validation Only              ║');
  print('╚════════════════════════════════════════════════╝');
  print('');

  final parser = YamlParser(
    eventsPath: path.join(projectRoot, config.eventsPath),
    log: verbose ? (message) => print(message) : null,
  );

  try {
    final domains = await parser.parseEvents();

    if (domains.isEmpty) {
      print('No analytics events found.');
    } else {
      final totalEvents =
          domains.values.fold(0, (sum, d) => sum + d.eventCount);
      final totalParams =
          domains.values.fold(0, (sum, d) => sum + d.parameterCount);

      print('✓ Validation successful.');
      print('  Domains: ${domains.length}');
      print('  Events: $totalEvents');
      print('  Parameters: $totalParams');
    }
  } catch (e, stack) {
    print('✗ Validation failed: $e');
    if (verbose) {
      print('Stack trace: $stack');
    }
    exit(1);
  }
}

/// Runs generation once
Future<void> _generate(
  String projectRoot,
  AnalyticsConfig config, {
  required bool generateCode,
  required bool generateDocs,
  required bool generateExports,
  required bool verbose,
}) async {
  print('╔════════════════════════════════════════════════╗');
  print('║   Analytics Gen - Code Generation              ║');
  print('╚════════════════════════════════════════════════╝');
  print('');

  final startTime = DateTime.now();

  try {
    if (generateCode) {
      final codeGen = CodeGenerator(
        config: config,
        projectRoot: projectRoot,
        log: verbose ? (message) => print(message) : null,
      );
      await codeGen.generate();
      print('');
    }

    if (generateDocs) {
      final docsGen = DocsGenerator(
        config: config,
        projectRoot: projectRoot,
        log: verbose ? (message) => print(message) : null,
      );
      await docsGen.generate();
      print('');
    }

    if (generateExports) {
      final exportGen = ExportGenerator(
        config: config,
        projectRoot: projectRoot,
        log: verbose ? (message) => print(message) : null,
      );
      await exportGen.generate();
      print('');
    }

    final duration = DateTime.now().difference(startTime);
    print('✓ All generation tasks completed in ${duration.inMilliseconds}ms');
  } catch (e, stack) {
    print('✗ Generation failed: $e');
    print('Stack trace: $stack');
    exit(1);
  }
}

/// Runs generation in watch mode
Future<void> _watchMode(
  String projectRoot,
  AnalyticsConfig config, {
  required bool generateCode,
  required bool generateDocs,
  required bool generateExports,
  required bool verbose,
}) async {
  print('╔════════════════════════════════════════════════╗');
  print('║   Analytics Gen - Watch Mode                   ║');
  print('╚════════════════════════════════════════════════╝');
  print('');
  print('Watching for changes in: ${config.eventsPath}');
  print('Press Ctrl+C to stop');
  print('');

  // Run initial generation
  await _generate(
    projectRoot,
    config,
    generateCode: generateCode,
    generateDocs: generateDocs,
    generateExports: generateExports,
    verbose: verbose,
  );

  // Watch for changes
  final eventsDir = Directory(path.join(projectRoot, config.eventsPath));
  if (!eventsDir.existsSync()) {
    print('Error: Events directory does not exist: ${eventsDir.path}');
    exit(1);
  }

  await for (final event in eventsDir.watch(recursive: true)) {
    if (event.path.endsWith('.yaml') || event.path.endsWith('.yml')) {
      print('');
      print('Change detected: ${path.basename(event.path)}');
      print('Regenerating...');
      print('');

      await _generate(
        projectRoot,
        config,
        generateCode: generateCode,
        generateDocs: generateDocs,
        generateExports: generateExports,
        verbose: verbose,
      );
    }
  }
}
