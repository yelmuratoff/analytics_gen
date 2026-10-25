import 'package:analytics_gen/src/config/config_parser.dart';
import 'package:analytics_gen/src/generator/studio_generator.dart';
import 'package:args/args.dart';

import '../cli/arguments.dart';
import '../cli/cli_command.dart';
import '../cli/usage.dart';

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
  })  : _parser = parser ?? createStudioExportArgParser(),
        _configParser = configParser;

  final ArgParser _parser;
  final ConfigParser? _configParser;

  /// Runs the export.
  Future<void> run(List<String> arguments) => runCliCommand(
        arguments,
        parser: _parser,
        printUsage: (logger) => printStudioExportUsage(_parser, logger: logger),
        configParser: _configParser,
        command: _export,
      );

  Future<void> _export(CliInvocation invocation) async {
    final logger = invocation.logger;
    logger.info('Exporting to AnalyticsGen Studio format...');

    final outputFile = await StudioGenerator(
      config: invocation.config,
      projectRoot: invocation.projectRoot,
      configPath: invocation.configPath,
      log: logger,
    ).generate(outputPath: invocation.results['output'] as String?);

    logger.info('');
    logger.info('Exported: ${outputFile.path}');
    logger.info(
      'Open AnalyticsGen Studio → "Open Project" → select this file.',
    );
  }
}
