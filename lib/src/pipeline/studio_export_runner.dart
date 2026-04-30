import 'dart:io';

import 'package:analytics_gen/src/config/config_parser.dart';
import 'package:analytics_gen/src/generator/studio_generator.dart';
import 'package:analytics_gen/src/util/logger.dart';
import 'package:args/args.dart';

import '../cli/arguments.dart';
import '../config/config_loader.dart';

/// Standalone CLI entrypoint for generating only the AnalyticsGen Studio
/// project file. Equivalent to:
///
///   dart run analytics_gen:generate --studio --no-code --no-docs --no-exports
///
/// Kept as a convenience binary for users who only need the studio export.
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
      help: 'Output path for the studio project file '
          '(overrides outputs.studio in config).',
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
      final outputOverride = results['output'] as String?;

      final config = await loadAnalyticsConfig(
        projectRoot,
        configPath,
        logger: logger,
        parser: _configParser,
      );

      logger.info('Exporting to AnalyticsGen Studio format...');

      final outputFile = await StudioGenerator(
        config: config,
        projectRoot: projectRoot,
        configPath: configPath,
        log: logger,
      ).generate(outputPath: outputOverride);

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
}
