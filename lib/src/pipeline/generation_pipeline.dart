import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/core/exceptions.dart';
import 'package:analytics_gen/src/generator/code_generator.dart';
import 'package:analytics_gen/src/generator/docs_generator.dart';
import 'package:analytics_gen/src/generator/export_generator.dart';
import 'package:analytics_gen/src/generator/output_manager.dart';
import 'package:analytics_gen/src/generator/studio_generator.dart';
import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';
import 'package:analytics_gen/src/models/tracking_plan.dart';
import 'package:analytics_gen/src/pipeline/tracking_plan_loader.dart';
import 'package:analytics_gen/src/services/creation_date_injector.dart';
import 'package:analytics_gen/src/services/schema_evolution_checker.dart';
import 'package:analytics_gen/src/services/tracking_ledger.dart';
import 'package:analytics_gen/src/services/watcher_service.dart';
import 'package:analytics_gen/src/util/banner_printer.dart';
import 'package:analytics_gen/src/util/logger.dart';
import 'package:path/path.dart' as path;
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
    this.configPath = 'analytics_gen.yaml',
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

  /// Path to the source `analytics_gen.yaml` (relative to [projectRoot]).
  /// Used by the studio export task to embed the raw config in the project file.
  final String configPath;

  final SchemaEvolutionChecker _schemaChecker;
  final WatcherService _watcherService;
  final EventLoaderFactory _eventLoaderFactory;
  final YamlParserFactory _yamlParserFactory;

  /// Runs every requested generation task once.
  ///
  /// Throws the [AnalyticsParseException] or [AnalyticsAggregateException]
  /// from loading an invalid tracking plan, and an
  /// [AnalyticsGenerationException] when a generation task fails.
  Future<void> run(GenerationRequest request) async {
    printBanner('Analytics Gen - Code Generation', logger: request.logger);

    if (!request.hasArtifacts) {
      request.logger.info('No generation tasks were requested.');
      return;
    }

    final metrics = request.enableMetrics
        ? ConsoleMetrics(request.logger)
        : const NoOpMetrics();

    final parseSw = Stopwatch()..start();

    final loader = TrackingPlanLoader(
      projectRoot: projectRoot,
      config: config,
      eventLoaderFactory: _eventLoaderFactory,
      yamlParserFactory: _yamlParserFactory,
    );

    final rawPlan = await loader.load(request.logger);
    final plan = await _applyTrackingCreationDate(rawPlan, request.logger);
    final domains = plan.domains;
    final contexts = plan.contexts;

    parseSw.stop();
    final totalEvents =
        domains.values.fold<int>(0, (sum, d) => sum + d.events.length);
    metrics.recordParsing(parseSw.elapsed, domains.length, totalEvents);

    final exportsPath = config.outputs.exportsPath;
    if (exportsPath != null) {
      await _invokeTask(
        _GeneratorTask(
          label: 'Schema evolution check',
          invoke: () =>
              _schemaChecker.checkSchemaEvolution(domains, exportsPath),
        ),
        request.logger,
      );
    }

    final genSw = Stopwatch()..start();
    await _runTasks(_buildTasks(request, domains, contexts), request.logger);
    genSw.stop();
    metrics.recordGeneration(genSw.elapsed);
    request.logger.info(
        '✓ All generation tasks completed in ${genSw.elapsed.inMilliseconds}ms');
  }

  /// Runs the generation pipeline in watch mode.
  ///
  /// A failed run is reported and watching continues, so a half-edited YAML
  /// file does not end the session.
  Future<void> watch(GenerationRequest request) {
    return _watcherService.watch(
      eventsPath: config.inputs.eventsPath,
      onGenerate: () => _runAndReport(request),
    );
  }

  Future<void> _runAndReport(GenerationRequest request) async {
    try {
      await run(request);
    } on Exception catch (error, stackTrace) {
      request.logger.error('✗ Generation failed: $error');
      if (request.verbose) {
        request.logger.error('Stack trace: $stackTrace');
      }
    }
  }

  Future<TrackingPlan> _applyTrackingCreationDate(
    TrackingPlan plan,
    Logger logger,
  ) async {
    if (!config.meta.autoTrackingCreationDate) return plan;

    final ledgerPath = path.join(projectRoot, '.analytics_tracking.json');
    final ledger = TrackingLedger(ledgerPath: ledgerPath);

    final eventKeys = <String>[
      for (final entry in plan.domains.entries)
        for (final event in entry.value.events) '${entry.key}.${event.name}',
    ];

    final existingCount = (await ledger.load()).length;
    final entries = await ledger.reconcile(eventKeys);
    final newCount = entries.length - existingCount;
    logger.info(
      'Tracking ledger: ${entries.length} events tracked'
      '${newCount > 0 ? ' ($newCount new)' : ''}',
    );

    return const CreationDateInjector().inject(plan, entries);
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
            outputManager: const OutputManager(),
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
            outputManager: const OutputManager(),
          ).generate(domains),
        ),
      );
    }

    if (request.generateStudio) {
      tasks.add(
        _GeneratorTask(
          label: 'Studio export',
          invoke: () => StudioGenerator(
            config: config,
            projectRoot: projectRoot,
            configPath: configPath,
            log: rootLogger.scoped('Studio export'),
          ).generate(),
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
    } on AnalyticsException {
      rethrow;
    } on Exception catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AnalyticsGenerationException('${task.label} failed: $error'),
        stackTrace,
      );
    }
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
