import 'dart:io';

import 'package:args/args.dart';

import '../config/analytics_config.dart';
import '../config/config_loader.dart';
import '../config/config_parser.dart';
import '../pipeline/failure_report.dart';
import '../util/logger.dart';

/// The parsed arguments, logger and configuration a CLI command runs with.
final class CliInvocation {
  /// Creates the invocation of a command.
  const CliInvocation({
    required this.results,
    required this.logger,
    required this.verbose,
    required this.projectRoot,
    required this.configPath,
    required this.config,
  });

  /// The parsed command-line arguments.
  final ArgResults results;

  /// The logger configured by `--verbose`.
  final Logger logger;

  /// Whether `--verbose` is set.
  final bool verbose;

  /// The directory the command runs in.
  final String projectRoot;

  /// The config file path from `--config`, relative to [projectRoot].
  final String configPath;

  /// The configuration loaded from [configPath].
  final AnalyticsConfig config;
}

/// Runs one analytics_gen command from its command-line [arguments].
///
/// Parses [arguments] with [parser] and calls [printUsage] for `--help`.
/// Otherwise loads the config named by `--config` from [projectRoot], the
/// current directory by default, and runs [command]. Any failure is logged
/// and ends the process through [exitProcess] with exit code 1. With
/// `--verbose`, failures other than invalid input also print their stack
/// trace.
Future<void> runCliCommand(
  List<String> arguments, {
  required ArgParser parser,
  required void Function(Logger logger) printUsage,
  required Future<void> Function(CliInvocation invocation) command,
  ConfigParser? configParser,
  String? projectRoot,
  Never Function(int code) exitProcess = exit,
}) async {
  Logger logger = const ConsoleLogger();
  var verbose = false;
  try {
    final results = parser.parse(arguments);
    verbose = results['verbose'] as bool;
    final consoleLogger = ConsoleLogger(verbose: verbose);
    logger = consoleLogger;

    if (results['help'] as bool) {
      printUsage(consoleLogger);
      return;
    }

    final root = projectRoot ?? Directory.current.path;
    final configPath = results['config'] as String;
    final config = await loadAnalyticsConfig(
      root,
      configPath,
      logger: consoleLogger,
      parser: configParser,
    );

    await command(
      CliInvocation(
        results: results,
        logger: consoleLogger,
        verbose: verbose,
        projectRoot: root,
        configPath: configPath,
        config: config,
      ),
    );
  } catch (e, stackTrace) {
    logger.error('Error: $e');
    if (verbose && !isInvalidInputError(e)) {
      logger.error('Stack trace: $stackTrace');
    }
    exitProcess(1);
  }
}
