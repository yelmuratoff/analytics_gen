import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:args/args.dart';

/// Creates an argument parser for the analytics code generator CLI.
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
      'plan',
      abbr: 'p',
      negatable: false,
      help: 'Print the parsed tracking plan and exit.',
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

/// Resolves the docs flag based on the command-line arguments and config.
bool resolveDocsFlag(ArgResults results, AnalyticsConfig config) {
  if (results.wasParsed('docs')) {
    return results['docs'] as bool;
  }
  return config.generateDocs;
}

/// Resolves the exports flag based on the command-line arguments and config.
bool resolveExportsFlag(ArgResults results, AnalyticsConfig config) {
  if (results.wasParsed('exports')) {
    return results['exports'] as bool;
  }
  return config.generateCsv || config.generateJson || config.generateSql;
}
