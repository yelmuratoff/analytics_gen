import 'dart:io';

import 'package:analytics_gen/src/config/config_parser.dart';
import 'package:analytics_gen/src/util/logger.dart';
import 'package:args/args.dart';

import '../config/config_loader.dart';
import '../pipeline/generation_pipeline.dart';
import '../pipeline/generation_request.dart';
import '../pipeline/plan_printer.dart';
import 'arguments.dart';
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
  Future<void> run(List<String> arguments) async {
    Logger? logger;
    try {
      final results = _parser.parse(arguments);
      final verbose = results['verbose'] as bool;
      logger = ConsoleLogger(verbose: verbose);

      if (results['help'] as bool) {
        printUsage(_parser, logger: logger);
        return;
      }

      final projectRoot = Directory.current.path;
      final configPath = results['config'] as String;
      final config = await loadAnalyticsConfig(
        projectRoot,
        configPath,
        logger: logger,
        parser: _configParser,
      );

      final generateCode = results['code'] as bool;
      final generateDocs = resolveDocsFlag(results, config);
      final generateExports = resolveExportsFlag(results, config);
      final watch = results['watch'] as bool;
      final planOnly = results['plan'] as bool;
      final validateOnly = results['validate-only'] as bool;
      final enableMetrics = results['metrics'] as bool;

      _ensureNotCombined('plan', planOnly, 'watch', watch, logger);
      _ensureNotCombined(
          'plan', planOnly, 'validate-only', validateOnly, logger);
      _ensureNotCombined('validate-only', validateOnly, 'watch', watch, logger);

      if (planOnly) {
        await printTrackingPlan(
          projectRoot,
          config,
          logger: logger,
        );
        return;
      }

      if (validateOnly) {
        await validateTrackingPlan(
          projectRoot,
          config,
          logger: logger,
        );
        return;
      }

      final request = GenerationRequest(
        generateCode: generateCode,
        generateDocs: generateDocs,
        generateExports: generateExports,
        verbose: verbose,
        enableMetrics: enableMetrics,
        logger: logger,
      );

      final pipeline = GenerationPipeline(
        projectRoot: projectRoot,
        config: config,
      );

      if (watch) {
        await pipeline.watch(request);
      } else {
        await pipeline.run(request);
      }
    } catch (e) {
      (logger ?? const ConsoleLogger()).error('Error: $e');
      exit(1);
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
