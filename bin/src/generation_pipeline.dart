import 'dart:io';

import 'package:analytics_gen/src/cli/watch_scheduler.dart';
import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/generator/code_generator.dart';
import 'package:analytics_gen/src/generator/docs_generator.dart';
import 'package:analytics_gen/src/generator/export_generator.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:analytics_gen/src/parser/event_loader.dart';
import 'package:analytics_gen/src/parser/yaml_parser.dart';
import 'package:analytics_gen/src/util/logger.dart';
import 'package:path/path.dart' as path;

import 'banner_printer.dart';
import 'generation_request.dart';

class GenerationPipeline {
  GenerationPipeline({
    required this.projectRoot,
    required this.config,
  });

  final String projectRoot;
  final AnalyticsConfig config;

  Future<void> run(GenerationRequest request) async {
    printBanner('Analytics Gen - Code Generation', logger: request.logger);

    if (!request.hasArtifacts) {
      request.logger.info('No generation tasks were requested.');
      return;
    }

    // Load files
    final loader = EventLoader(
      eventsPath: path.join(projectRoot, config.eventsPath),
      contextFiles: config.contexts
          .map((c) => path.join(projectRoot, c))
          .toList(), // Resolve paths
      log: request.logger,
    );
    final eventSources = await loader.loadEventFiles();
    final contextSources = await loader.loadContextFiles();

    // Parse YAML files once
    final parser = YamlParser(
      log: request.logger,
      naming: config.naming,
    );
    final domains = await parser.parseEvents(eventSources);
    final contexts = await parser.parseContexts(contextSources);

    final tasks = _buildTasks(
      request,
      domains,
      contexts,
    );
    final startTime = DateTime.now();

    try {
      await _runTasks(tasks, request.logger);
      final duration = DateTime.now().difference(startTime);
      request.logger.info(
          '✓ All generation tasks completed in ${duration.inMilliseconds}ms');
    } on _TaskFailure catch (failure) {
      request.logger.error('✗ ${failure.label} failed: ${failure.error}');
      if (request.verbose) {
        request.logger.error('Stack trace: ${failure.stackTrace}');
      }
      exit(1);
    } catch (e, stack) {
      request.logger.error('✗ Generation failed: $e');
      if (request.verbose) {
        request.logger.error('Stack trace: $stack');
      }
      exit(1);
    }
  }

  Future<void> watch(GenerationRequest request) async {
    printBanner('Analytics Gen - Watch Mode', logger: request.logger);
    request.logger.info('');
    request.logger.info('Watching for changes in: ${config.eventsPath}');
    request.logger.info('Press Ctrl+C to stop');
    request.logger.info('');

    await run(request);

    final eventsDir = Directory(path.join(projectRoot, config.eventsPath));
    if (!eventsDir.existsSync()) {
      request.logger
          .error('Error: Events directory does not exist: ${eventsDir.path}');
      exit(1);
    }

    final scheduler = WatchRegenerationScheduler(
      onGenerate: () async {
        request.logger.info('');
        request.logger.info('Regenerating...');
        request.logger.info('');
        await run(request);
      },
    );

    try {
      await for (final event in eventsDir.watch(recursive: true)) {
        if (event.path.endsWith('.yaml') || event.path.endsWith('.yml')) {
          request.logger.info('');
          request.logger.info('Change detected: ${path.basename(event.path)}');
          scheduler.schedule();
        }
      }
    } finally {
      scheduler.dispose();
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
