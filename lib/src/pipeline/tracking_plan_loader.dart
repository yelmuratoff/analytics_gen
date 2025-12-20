import 'package:path/path.dart' as path;

import '../config/analytics_config.dart';
import '../config/parser_config.dart';
import '../models/analytics_parameter.dart';
import '../models/tracking_plan.dart';
import '../parser/event_loader.dart';
import '../parser/yaml_parser.dart';
import '../util/logger.dart';
import 'pipeline_factories.dart';

/// Orchestrates the multi-stage loading and parsing of a tracking plan.
///
/// This ensures that validation and generation use the exact same logic
/// for loading shared parameters, contexts, and enforcing rules.
final class TrackingPlanLoader {
  /// Creates a new tracking plan loader.
  TrackingPlanLoader({
    required this.projectRoot,
    required this.config,
    EventLoaderFactory? eventLoaderFactory,
    YamlParserFactory? yamlParserFactory,
  })  : _eventLoaderFactory =
            eventLoaderFactory ?? const DefaultEventLoaderFactory(),
        _yamlParserFactory =
            yamlParserFactory ?? const DefaultYamlParserFactory();

  /// The root directory of the project.
  final String projectRoot;

  /// The analytics configuration.
  final AnalyticsConfig config;

  final EventLoaderFactory _eventLoaderFactory;
  final YamlParserFactory _yamlParserFactory;

  /// Loads and parses the complete tracking plan.
  Future<TrackingPlan> load(Logger logger) async {
    // 1. Resolve paths
    final sharedParameterPaths = config.inputs.sharedParameters
        .map((p) => path.join(projectRoot, p))
        .toList();

    final contextPaths =
        config.inputs.contexts.map((c) => path.join(projectRoot, c)).toList();

    final eventsPath = path.join(projectRoot, config.inputs.eventsPath);

    // 2. Initialize loader
    final loader = _eventLoaderFactory.create(
      eventsPath: eventsPath,
      contextFiles: contextPaths,
      sharedParameterFiles: sharedParameterPaths,
      log: logger,
    );

    // 3. Load sources
    final eventSources = await loader.loadEventFiles();
    final contextSources = await loader.loadContextFiles();

    // 4. Load shared parameters first (they are needed for event parsing)
    final sharedParser = _yamlParserFactory.create(
      log: logger,
      config: ParserConfig(naming: config.naming),
    );

    final sharedParameters = await _loadSharedParameters(
      sharedParameterPaths,
      loader,
      logger,
      sharedParser,
    );

    // 5. Build full parser config with rules and shared parameters
    final parser = _yamlParserFactory.create(
      log: logger,
      config: ParserConfig(
        naming: config.naming,
        strictEventNames: config.rules.strictEventNames,
        enforceCentrallyDefinedParameters:
            config.rules.enforceCentrallyDefinedParameters,
        preventEventParameterDuplicates:
            config.rules.preventEventParameterDuplicates,
        sharedParameters: sharedParameters,
      ),
    );

    // 6. Parse everything
    final domains = await parser.parseEvents(eventSources);
    final contexts = await parser.parseContexts(contextSources);

    return TrackingPlan(
      domains: domains,
      contexts: contexts,
    );
  }

  Future<Map<String, AnalyticsParameter>> _loadSharedParameters(
    List<String> paths,
    EventLoader loader,
    Logger logger,
    YamlParser parser,
  ) async {
    final Map<String, AnalyticsParameter> sharedParameters = {};
    if (paths.isEmpty) return sharedParameters;

    for (final sharedPath in paths) {
      final sharedSource = await loader.loadSourceFile(sharedPath);
      if (sharedSource != null) {
        try {
          final params = parser.parseSharedParameters(sharedSource);
          sharedParameters.addAll(params);
        } catch (e) {
          logger.error('Failed to parse shared parameters at $sharedPath: $e');
          rethrow;
        }
      }
    }
    return sharedParameters;
  }
}
