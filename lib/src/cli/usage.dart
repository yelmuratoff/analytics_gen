import 'package:analytics_gen/src/util/logger.dart';
import 'package:args/args.dart';

/// Prints usage information for the `generate` command.
void printUsage(ArgParser parser, {Logger? logger}) {
  printCommandUsage(
    title: 'Analytics Gen - Code generator for type-safe analytics events',
    command: 'generate',
    parser: parser,
    examples: const [
      ('Generate code only', 'dart run analytics_gen:generate'),
      (
        'Generate code and documentation',
        'dart run analytics_gen:generate --docs'
      ),
      (
        'Generate everything',
        'dart run analytics_gen:generate --docs --exports',
      ),
      ('Watch mode', 'dart run analytics_gen:generate --watch'),
      (
        'Validate YAML only (no files written)',
        'dart run analytics_gen:generate --validate-only',
      ),
    ],
    logger: logger,
  );
}

/// Prints usage information for the `audit` command.
void printAuditUsage(ArgParser parser, {Logger? logger}) {
  printCommandUsage(
    title: 'Analytics Gen - Dead event audit\n'
        '\n'
        'Lists tracking plan events whose generated logging method is never '
        'called from lib/.',
    command: 'audit',
    parser: parser,
    logger: logger,
  );
}

/// Prints usage information for the `studio_export` command.
void printStudioExportUsage(ArgParser parser, {Logger? logger}) {
  printCommandUsage(
    title: 'AnalyticsGen Studio Export',
    command: 'studio_export',
    parser: parser,
    logger: logger,
  );
}

/// Prints the [title], the usage line of [command], the options of [parser]
/// and each of the [examples] as a description and a command line.
void printCommandUsage({
  required String title,
  required String command,
  required ArgParser parser,
  List<(String, String)> examples = const [],
  Logger? logger,
}) {
  final log = logger ?? const ConsoleLogger();
  log.info(title);
  log.info('');
  log.info('Usage: dart run analytics_gen:$command [options]');
  log.info('');
  log.info('Options:');
  log.info(parser.usage);
  if (examples.isEmpty) return;
  log.info('');
  log.info('Examples:');
  for (final (index, (description, commandLine)) in examples.indexed) {
    if (index > 0) log.info('');
    log.info('  # $description');
    log.info('  $commandLine');
  }
}
