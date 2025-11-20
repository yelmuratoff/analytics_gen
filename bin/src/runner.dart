import 'dart:io';

import 'package:analytics_gen/src/util/logger.dart';
import 'package:args/args.dart';

import 'arguments.dart';
import 'config_loader.dart';
import 'generation_pipeline.dart';
import 'generation_request.dart';
import 'plan_printer.dart';
import 'usage.dart';

class AnalyticsGenRunner {
  AnalyticsGenRunner({ArgParser? parser})
      : _parser = parser ?? createArgParser();

  final ArgParser _parser;

  Future<void> run(List<String> arguments) async {
    try {
      final results = _parser.parse(arguments);

      if (results['help'] as bool) {
        printUsage(_parser);
        return;
      }

      final projectRoot = Directory.current.path;
      final configPath = results['config'] as String;
      final config = await loadAnalyticsConfig(projectRoot, configPath);

      final generateCode = results['code'] as bool;
      final generateDocs = resolveDocsFlag(results, config);
      final generateExports = resolveExportsFlag(results, config);
      final verbose = results['verbose'] as bool;
      final watch = results['watch'] as bool;
      final planOnly = results['plan'] as bool;
      final validateOnly = results['validate-only'] as bool;

      _ensureNotCombined('plan', planOnly, 'watch', watch);
      _ensureNotCombined('plan', planOnly, 'validate-only', validateOnly);
      _ensureNotCombined('validate-only', validateOnly, 'watch', watch);

      if (planOnly) {
        await printTrackingPlan(
          projectRoot,
          config,
          verbose: verbose,
        );
        return;
      }

      if (validateOnly) {
        await validateTrackingPlan(
          projectRoot,
          config,
          verbose: verbose,
        );
        return;
      }

      final request = GenerationRequest(
        generateCode: generateCode,
        generateDocs: generateDocs,
        generateExports: generateExports,
        verbose: verbose,
        logger: ConsoleLogger(verbose: verbose),
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
      print('Error: $e');
      exit(1);
    }
  }

  void _ensureNotCombined(
    String primaryFlag,
    bool primaryValue,
    String secondaryFlag,
    bool secondaryValue,
  ) {
    if (primaryValue && secondaryValue) {
      print(
          'Error: --$primaryFlag cannot be used together with --$secondaryFlag.');
      exit(1);
    }
  }
}
