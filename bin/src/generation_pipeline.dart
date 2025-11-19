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
    );
    final domains = await parser.parseEvents();

    final tasks = _buildTasks(request, domains);
    final startTime = DateTime.now();

    try {
      // Run tasks in parallel where possible, but for now sequential is safer for logging
      // Actually, since we have separate loggers or sequential logging, let's keep sequential execution
      // of top-level tasks to avoid interleaved log output, but the tasks themselves are optimized.
      for (final task in tasks) {
        await task.invoke();
        print('');
      }

      final duration = DateTime.now().difference(startTime);
      print('✓ All generation tasks completed in ${duration.inMilliseconds}ms');
    } catch (e, stack) {
      print('✗ Generation failed: $e');
      print('Stack trace: $stack');
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
  ) {
    final tasks = <_GeneratorTask>[];
    final log = request.logger;

    if (request.generateCode) {
      tasks.add(
        _GeneratorTask(
          label: 'Code generation',
          invoke: () => CodeGenerator(
            config: config,
            projectRoot: projectRoot,
            log: log,
          ).generate(domains),
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
            log: log,
          ).generate(domains),
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
            log: log,
          ).generate(domains),
        ),
      );
    }

    return tasks;
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
