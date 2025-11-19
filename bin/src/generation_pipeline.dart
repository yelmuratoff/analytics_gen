import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:analytics_gen/src/cli/watch_scheduler.dart';
import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/generator/code_generator.dart';
import 'package:analytics_gen/src/generator/docs_generator.dart';
import 'package:analytics_gen/src/generator/export_generator.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:analytics_gen/src/parser/yaml_parser.dart';

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
    printBanner('Analytics Gen - Code Generation');

    if (!request.hasArtifacts) {
      print('No generation tasks were requested.');
      return;
    }

    // Parse YAML files once
    final parser = YamlParser(
      eventsPath: path.join(projectRoot, config.eventsPath),
      log: request.logger,
      naming: config.naming,
      contextFiles: config.contexts
          .map((c) => path.join(projectRoot, c))
          .toList(), // Resolve paths
    );
    final domains = await parser.parseEvents();
    final userProperties = await parser.parseUserProperties();
    final globalContext = await parser.parseGlobalContext();
    final contexts = await parser.parseContexts();

    // Merge legacy contexts if they exist
    if (userProperties.isNotEmpty) {
      contexts['user_properties'] = userProperties;
    }
    if (globalContext.isNotEmpty) {
      contexts['global_context'] = globalContext;
    }

    final tasks = _buildTasks(
      request,
      domains,
      contexts,
    );
    final startTime = DateTime.now();

    try {
      await _runTasks(tasks);
      final duration = DateTime.now().difference(startTime);
      print('✓ All generation tasks completed in ${duration.inMilliseconds}ms');
    } on _TaskFailure catch (failure) {
      print('✗ ${failure.label} failed: ${failure.error}');
      if (request.verbose) {
        print('Stack trace: ${failure.stackTrace}');
      }
      exit(1);
    } catch (e, stack) {
      print('✗ Generation failed: $e');
      if (request.verbose) {
        print('Stack trace: $stack');
      }
      exit(1);
    }
  }

  Future<void> watch(GenerationRequest request) async {
    printBanner('Analytics Gen - Watch Mode');
    print('');
    print('Watching for changes in: ${config.eventsPath}');
    print('Press Ctrl+C to stop');
    print('');

    await run(request);

    final eventsDir = Directory(path.join(projectRoot, config.eventsPath));
    if (!eventsDir.existsSync()) {
      print('Error: Events directory does not exist: ${eventsDir.path}');
      exit(1);
    }

    final scheduler = WatchRegenerationScheduler(
      onGenerate: () async {
        print('');
        print('Regenerating...');
        print('');
        await run(request);
      },
    );

    try {
      await for (final event in eventsDir.watch(recursive: true)) {
        if (event.path.endsWith('.yaml') || event.path.endsWith('.yml')) {
          print('');
          print('Change detected: ${path.basename(event.path)}');
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
            log: _scopedLogger('Code generation', rootLogger),
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
            log: _scopedLogger('Documentation generation', rootLogger),
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
            log: _scopedLogger('Export generation', rootLogger),
          ).generate(domains),
        ),
      );
    }

    return tasks;
  }

  Future<void> _runTasks(List<_GeneratorTask> tasks) async {
    if (tasks.isEmpty) return;

    if (tasks.length == 1) {
      await _invokeTask(tasks.single);
      print('');
      return;
    }

    await Future.wait(tasks.map(_invokeTask));
    print('');
  }

  Future<void> _invokeTask(_GeneratorTask task) async {
    try {
      await task.invoke();
      print('✓ ${task.label} completed');
    } catch (error, stackTrace) {
      throw _TaskFailure(task.label, error, stackTrace);
    }
  }

  Logger? _scopedLogger(String label, Logger? root) {
    if (root == null) return null;
    return (message) => root('[$label] $message');
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
