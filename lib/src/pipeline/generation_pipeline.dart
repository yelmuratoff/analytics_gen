import 'dart:io';

import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/generator/code_generator.dart';
import 'package:analytics_gen/src/generator/docs_generator.dart';
import 'package:analytics_gen/src/generator/export_generator.dart';
import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';
import 'package:analytics_gen/src/pipeline/tracking_plan_loader.dart';
import 'package:analytics_gen/src/services/schema_evolution_checker.dart';
import 'package:analytics_gen/src/services/watcher_service.dart';
import 'package:analytics_gen/src/util/banner_printer.dart';
import 'package:analytics_gen/src/util/logger.dart';
import '../metrics/console_metrics.dart';
import '../metrics/metrics.dart';

import 'generation_request.dart';
import 'pipeline_factories.dart';

/// Generation pipeline for the analytics code generator.
class GenerationPipeline {
  /// Creates a new generation pipeline.
  GenerationPipeline({
    required this.projectRoot,
    required this.config,
    SchemaEvolutionChecker? schemaChecker,
    WatcherService? watcherService,
    EventLoaderFactory? eventLoaderFactory,
    YamlParserFactory? yamlParserFactory,
    Logger logger = const ConsoleLogger(),
  })  : _schemaChecker = schemaChecker ??
            SchemaEvolutionChecker(projectRoot: projectRoot, logger: logger),
        _watcherService = watcherService ??
            WatcherService(projectRoot: projectRoot, logger: logger),
        _eventLoaderFactory =
            eventLoaderFactory ?? const DefaultEventLoaderFactory(),
        _yamlParserFactory =
            yamlParserFactory ?? const DefaultYamlParserFactory();

  /// The root directory of the project.
  final String projectRoot;

  /// The analytics configuration.
  final AnalyticsConfig config;

  final SchemaEvolutionChecker _schemaChecker;
  final WatcherService _watcherService;
  final EventLoaderFactory _eventLoaderFactory;
  final YamlParserFactory _yamlParserFactory;

  /// Runs the generation pipeline.
  Future<void> run(GenerationRequest request) async {
    printBanner('Analytics Gen - Code Generation', logger: request.logger);

    if (!request.hasArtifacts) {
      request.logger.info('No generation tasks were requested.');
      return;
    }

    final metrics = request.enableMetrics
        ? ConsoleMetrics(request.logger)
        : const NoOpMetrics();

    try {
      final parseSw = Stopwatch()..start();

      final loader = TrackingPlanLoader(
        projectRoot: projectRoot,
        config: config,
        eventLoaderFactory: _eventLoaderFactory,
        yamlParserFactory: _yamlParserFactory,
      );

      final plan = await loader.load(request.logger);
      final domains = plan.domains;
      final contexts = plan.contexts;

      parseSw.stop();
      final totalEvents =
          domains.values.fold<int>(0, (sum, d) => sum + d.events.length);
      metrics.recordParsing(parseSw.elapsed, domains.length, totalEvents);

      final tasks = _buildTasks(
        request,
        domains,
        contexts,
      );

      final schemaCheckTask =
          tasks.where((t) => t.label == 'Schema evolution check').firstOrNull;

      if (schemaCheckTask != null) {
        tasks.remove(schemaCheckTask);
        await _invokeTask(schemaCheckTask, request.logger);
      }
      final startTime = DateTime.now();

      final genSw = Stopwatch()..start();
      await _runTasks(tasks, request.logger);
      metrics.recordGeneration(genSw.elapsed, 0); // 0 file count for now
      final duration = DateTime.now().difference(startTime);
      request.logger.info(
          '✓ All generation tasks completed in ${duration.inMilliseconds}ms');
    } on _TaskFailure catch (failure) {
      _handleError(request, failure.label, failure.error, failure.stackTrace);
    } catch (e, stack) {
      _handleError(request, 'Generation', e, stack);
    }
  }

  /// Runs the generation pipeline in watch mode.
  Future<void> watch(GenerationRequest request) async {
    try {
      await _watcherService.watch(
          eventsPath: config.inputs.eventsPath, onGenerate: () => run(request));
    } catch (e) {
      request.logger.error('Watch error: $e');
      exit(1);
    }
  }

  List<_GeneratorTask> _buildTasks(
    GenerationRequest request,
    Map<String, AnalyticsDomain> domains,
    Map<String, List<AnalyticsParameter>> contexts,
  ) {
    final tasks = <_GeneratorTask>[];
    final rootLogger = request.logger;

    if (request.generateCode) {
      tasks.add(
        _GeneratorTask(
          label: 'Code generation',
          invoke: () => CodeGenerator(
            config: config,
            projectRoot: projectRoot,
            log: rootLogger.scoped('Code generation'),
          ).generate(
            domains,
            contexts: contexts,
          ),
        ),
      );
    }

    if (request.generateDocs) {
      tasks.add(
        _GeneratorTask(
          label: 'Documentation generation',
          invoke: () => DocsGenerator(
            config: config,
            projectRoot: projectRoot,
            log: rootLogger.scoped('Documentation generation'),
          ).generate(
            domains,
            contexts: contexts,
          ),
        ),
      );
    }

    if (request.generateExports) {
      tasks.add(
        _GeneratorTask(
          label: 'Export generation',
          invoke: () => ExportGenerator(
            config: config,
            projectRoot: projectRoot,
            log: rootLogger.scoped('Export generation'),
          ).generate(domains),
        ),
      );
    }

    // Schema evolution check
    if (config.outputs.exportsPath != null) {
      tasks.add(
        _GeneratorTask(
          label: 'Schema evolution check',
          invoke: () => _schemaChecker.checkSchemaEvolution(
            domains,
            config.outputs.exportsPath,
          ),
        ),
      );
    }

    return tasks;
  }

  Future<void> _runTasks(List<_GeneratorTask> tasks, Logger logger) async {
    if (tasks.isEmpty) return;

    if (tasks.length == 1) {
      await _invokeTask(tasks.single, logger);
      logger.info('');
      return;
    }

    await Future.wait(tasks.map((t) => _invokeTask(t, logger)));
    logger.info('');
  }

  Future<void> _invokeTask(_GeneratorTask task, Logger logger) async {
    try {
      await task.invoke();
      logger.info('✓ ${task.label} completed');
    } catch (error, stackTrace) {
      throw _TaskFailure(task.label, error, stackTrace);
    }
  }

  void _handleError(GenerationRequest request, String context, Object error,
      StackTrace stack) {
    request.logger.error('✗ $context failed: $error');
    if (request.verbose) {
      request.logger.error('Stack trace: $stack');
    }
    exit(1);
  }
}

class _GeneratorTask {
  _GeneratorTask({
    required this.label,
    required this.invoke,
  });

  final String label;
  final Future<void> Function() invoke;
}

final class _TaskFailure implements Exception {
  _TaskFailure(this.label, this.error, this.stackTrace);

  final String label;
  final Object error;
  final StackTrace stackTrace;

  @override
  String toString() => '$label failed: $error';
}
