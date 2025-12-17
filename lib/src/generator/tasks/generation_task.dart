import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';
import 'package:analytics_gen/src/util/logger.dart';
import 'package:path/path.dart' as path;

import '../output_manager.dart';
import '../renderers/analytics_class_renderer.dart';
import '../renderers/context_renderer.dart';
import '../renderers/event_renderer.dart';
import '../renderers/matchers_renderer.dart';

/// Context object holding shared state for the generation process.
class GenerationContext {
  /// Creates a new generation context.
  GenerationContext({
    required this.config,
    required this.domains,
    required this.projectRoot,
    required this.logger,
    required this.outputManager,
    required this.eventRenderer,
    required this.contextRenderer,
    required this.classRenderer,
    required this.matchersRenderer,
    this.contexts = const {},
  });

  /// The analytics configuration.
  final AnalyticsConfig config;

  /// The map of analytics domains to generate.
  final Map<String, AnalyticsDomain> domains;

  /// The map of contexts to generate.
  final Map<String, List<AnalyticsParameter>> contexts;

  /// The project root directory (absolute path).
  final String projectRoot;

  /// The logger to use for output.
  final Logger logger;

  /// Manager for file system operations.
  final OutputManager outputManager;

  /// Renderer for event files.
  final EventRenderer eventRenderer;

  /// Renderer for context files.
  final ContextRenderer contextRenderer;

  /// Renderer for the main analytics class.
  final AnalyticsClassRenderer classRenderer;

  /// Renderer for test matchers.
  final MatchersRenderer matchersRenderer;

  /// The directory where generated files are placed.
  String get outputDir => path.join(projectRoot, 'lib', config.outputPath);

  /// The directory where event files are placed.
  String get eventsDir => path.join(outputDir, 'events');

  /// The directory where context files are placed.
  String get contextsDir => path.join(outputDir, 'contexts');

  /// Set of file paths generated during the execution of tasks.
  /// Used for stale file cleanup.
  final Set<String> generatedFiles = {};
}

/// Abstract base class for a single unit of work in the generation pipeline.
abstract class GenerationTask {
  /// Executes the task.
  Future<void> execute(GenerationContext context);
}

/// Executes a series of generation tasks.
class TaskRunner {
  /// Executes the provided [tasks] in order.
  Future<void> execute(
    List<GenerationTask> tasks,
    GenerationContext context,
  ) async {
    for (final task in tasks) {
      context.logger.debug('Running task: ${task.runtimeType}');
      await task.execute(context);
    }
  }
}
