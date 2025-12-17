import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';

import '../config/analytics_config.dart';
import '../util/logger.dart';
import 'output_manager.dart';

import 'renderers/analytics_class_renderer.dart';
import 'renderers/context_renderer.dart';
import 'renderers/default_renderer_factory.dart';
import 'renderers/event_renderer.dart';
import 'renderers/matchers_renderer.dart';
import 'renderers/renderer_factory.dart';
import 'serializers/plan_serializer.dart';

import 'tasks/clean_stale_files_task.dart';
import 'tasks/generate_analytics_class_task.dart';
import 'tasks/generate_barrel_file_task.dart';
import 'tasks/generate_context_files_task.dart';
import 'tasks/generate_domain_files_task.dart';
import 'tasks/generate_matchers_task.dart';
import 'tasks/generation_task.dart';
import 'tasks/prepare_directories_task.dart';

/// Generates Dart code for analytics events from YAML configuration.
final class CodeGenerator {
  /// Creates a new code generator.
  CodeGenerator({
    required this.config,
    required this.projectRoot,
    this.log = const NoOpLogger(),
    AnalyticsClassRenderer? classRenderer,
    ContextRenderer? contextRenderer,
    RendererFactory rendererFactory = const DefaultRendererFactory(),
    MatchersRenderer? matchersRenderer,
    OutputManager? outputManager,
    PlanSerializer? planSerializer,
  })  : _classRenderer = classRenderer ??
            AnalyticsClassRenderer(
              config,
              planSerializer: planSerializer ?? const PlanSerializer(),
            ),
        _contextRenderer = contextRenderer ?? const ContextRenderer(),
        _eventRenderer = rendererFactory.createEventRenderer(config),
        _matchersRenderer = matchersRenderer ?? MatchersRenderer(config),
        _outputManager = outputManager ?? const OutputManager();

  /// The analytics configuration.
  final AnalyticsConfig config;

  /// The root directory of the project.
  final String projectRoot;

  /// The logger to use.
  final Logger log;

  final AnalyticsClassRenderer _classRenderer;
  final ContextRenderer _contextRenderer;
  final EventRenderer _eventRenderer;

  final MatchersRenderer _matchersRenderer;
  final OutputManager _outputManager;

  /// Generates analytics code and writes to configured output path
  Future<void> generate(
    Map<String, AnalyticsDomain> domains, {
    Map<String, List<AnalyticsParameter>> contexts = const {},
  }) async {
    // Filter out empty contexts to avoid generating empty files
    final activeContexts = Map<String, List<AnalyticsParameter>>.from(contexts)
      ..removeWhere((_, value) => value.isEmpty);

    if (domains.isEmpty && activeContexts.isEmpty) {
      log.warning(
          'No analytics events or properties found. Skipping generation.');
      return;
    }

    final context = GenerationContext(
      config: config,
      domains: domains,
      contexts: activeContexts,
      projectRoot: projectRoot,
      logger: log,
      outputManager: _outputManager,
      eventRenderer: _eventRenderer,
      contextRenderer: _contextRenderer,
      classRenderer: _classRenderer,
      matchersRenderer: _matchersRenderer,
    );

    final tasks = [
      PrepareDirectoriesTask(),
      GenerateDomainFilesTask(),
      GenerateContextFilesTask(),
      CleanStaleFilesTask(),
      GenerateBarrelFileTask(),
      GenerateAnalyticsClassTask(),
      if (config.generateTestMatchers) GenerateMatchersTask(),
    ];

    await TaskRunner().execute(tasks, context);
  }
}
