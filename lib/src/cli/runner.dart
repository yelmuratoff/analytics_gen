import 'dart:io';

import 'package:analytics_gen/src/config/config_parser.dart';
import 'package:analytics_gen/src/util/logger.dart';
import 'package:args/args.dart';

import '../pipeline/generation_pipeline.dart';
import '../pipeline/generation_request.dart';
import '../pipeline/plan_printer.dart';
import 'arguments.dart';
import 'cli_command.dart';
import 'usage.dart';

/// Runner for the analytics code generator CLI.
class AnalyticsGenRunner {
  /// Creates a new analytics runner.
  AnalyticsGenRunner({
    ArgParser? parser,
    ConfigParser? configParser,
  })  : _parser = parser ?? createArgParser(),
        _configParser = configParser;

  final ArgParser _parser;
  final ConfigParser? _configParser;

  /// Runs the generator.
  Future<void> run(List<String> arguments) => runCliCommand(
        arguments,
        parser: _parser,
        printUsage: (logger) => printUsage(_parser, logger: logger),
        configParser: _configParser,
        command: _generate,
      );

  Future<void> _generate(CliInvocation invocation) async {
    final CliInvocation(:results, :logger, :projectRoot, :config) = invocation;

    final watch = results['watch'] as bool;
    final planOnly = results['plan'] as bool;
    final validateOnly = results['validate-only'] as bool;

    _ensureNotCombined('plan', planOnly, 'watch', watch, logger);
    _ensureNotCombined('plan', planOnly, 'validate-only', validateOnly, logger);
    _ensureNotCombined('validate-only', validateOnly, 'watch', watch, logger);

    if (planOnly) {
      await printTrackingPlan(projectRoot, config, logger: logger);
      return;
    }

    if (validateOnly) {
      await validateTrackingPlan(projectRoot, config, logger: logger);
      return;
    }

    final request = GenerationRequest(
      generateCode: results['code'] as bool,
      generateDocs: resolveDocsFlag(results, config),
      generateExports: resolveExportsFlag(results, config),
      generateStudio: resolveStudioFlag(results, config),
      verbose: invocation.verbose,
      enableMetrics: results['metrics'] as bool,
      logger: logger,
    );

    final pipeline = GenerationPipeline(
      projectRoot: projectRoot,
      config: config,
      configPath: invocation.configPath,
    );

    if (watch) {
      await pipeline.watch(request);
    } else {
      await pipeline.run(request);
    }
  }

  void _ensureNotCombined(
    String primaryFlag,
    bool primaryValue,
    String secondaryFlag,
    bool secondaryValue,
    Logger logger,
  ) {
    if (primaryValue && secondaryValue) {
      logger.error(
          'Error: --$primaryFlag cannot be used together with --$secondaryFlag.');
      exit(1);
    }
  }
}
