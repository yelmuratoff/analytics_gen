import 'dart:io';

import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/config/config_parser.dart';
import 'package:analytics_gen/src/config/parser_config.dart';
import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';
import 'package:analytics_gen/src/parser/event_loader.dart';
import 'package:analytics_gen/src/parser/yaml_parser.dart';
import 'package:analytics_gen/src/util/event_naming.dart';
import 'package:analytics_gen/src/util/logger.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import '../cli/arguments.dart';
import '../cli/usage.dart';
import '../config/config_loader.dart';
import '../services/git_service.dart';

/// Runner for the dead event audit tool.
class AuditRunner {
  /// Creates a new audit runner.
  AuditRunner({
    ArgParser? parser,
    ConfigParser? configParser,
  })  : _parser = parser ?? createArgParser(),
        _configParser = configParser;

  final ArgParser _parser;
  final ConfigParser? _configParser;

  /// Runs the audit.
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

      await _runAudit(projectRoot, config, logger);
    } catch (e) {
      (logger ?? const ConsoleLogger()).error('Error: $e');
      exit(1);
    }
  }

  Future<void> _runAudit(
    String projectRoot,
    AnalyticsConfig config,
    Logger logger,
  ) async {
    logger.info('Starting "Dead Event" Audit...');

    // 1. Load Defined Events
    final domains = await _loadDomains(projectRoot, config, logger);
    if (domains.isEmpty) {
      logger.warning('No events found in definition files.');
      return;
    }

    final totalEvents = domains.values.fold(0, (sum, d) => sum + d.eventCount);
    logger.info('Found $totalEvents events in definitions.');

    // 2. Compute Expected Method Names
    final eventCalls = <String, _EventDefinition>{};
    for (final domainName in domains.keys) {
      final domain = domains[domainName]!;
      for (final event in domain.events) {
        final methodName =
            EventNaming.buildLoggerMethodName(domainName, event.name);
        eventCalls[methodName] = _EventDefinition(
          domainName: domainName,
          eventName: event.name,
          event: event,
        );
      }
    }

    // 3. Scan Codebase using AnalysisContextCollection
    final libPath = path.join(projectRoot, 'lib');
    if (!Directory(libPath).existsSync()) {
      logger.error('Error: lib directory not found at $libPath');
      exit(1);
    }

    // Exclude generated files from scan?
    // We want to see usage in APP code. Generated files (implementation) definetely contain the method declaration,
    // but typically we want to find INVOCATIONS.
    // The AnalysisContextCollection will resolve everything.

    logger.info('Scanning codebase including: $libPath');

    final collection = AnalysisContextCollection(
      includedPaths: [libPath],
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );

    final usages = <String, int>{};
    for (final key in eventCalls.keys) {
      usages[key] = 0;
    }

    for (final context in collection.contexts) {
      for (final filePath in context.contextRoot.analyzedFiles()) {
        // Skip the generated analytics files themselves to avoid counting the definition as usage
        // Assuming generated files are in config.outputPath
        if (path.isWithin(
            path.join(projectRoot, 'lib', config.outputs.dartPath), filePath)) {
          continue;
        }

        if (!filePath.endsWith('.dart')) continue;

        final result = await context.currentSession.getResolvedUnit(filePath);
        if (result is ResolvedUnitResult) {
          if (!result.exists) continue;

          final visitor = _MethodInvocationVisitor(eventCalls.keys.toSet());
          result.unit.visitChildren(visitor);

          for (final method in visitor.foundMethods) {
            usages[method] = (usages[method] ?? 0) + 1;
          }
        }
      }
    }

    // 4. Report Results
    final unusedEvents = usages.entries.where((e) => e.value == 0).toList();

    if (unusedEvents.isEmpty) {
      logger.info('✓ All ${eventCalls.length} events are used.');
      return;
    }

    final gitService = GitService(logger: logger);

    logger.warning('Found ${unusedEvents.length} dead events (0 usages):');
    for (final entry in unusedEvents) {
      final def = eventCalls[entry.key]!;
      logger.warning(
          '  - ${def.domainName}.${def.eventName} (Method: ${entry.key})');

      if (def.event.sourcePath != null) {
        final relativePath =
            path.relative(def.event.sourcePath!, from: projectRoot);
        logger.warning('    Defined in: $relativePath:${def.event.lineNumber}');

        // Fetch git blame info
        if (def.event.lineNumber != null) {
          final blame = await gitService.getBlame(
              def.event.sourcePath!, def.event.lineNumber!);
          if (blame != null) {
            final daysAgo = DateTime.now().difference(blame.date).inDays;
            logger.warning(
                '    Last modified: ${blame.date.toString().substring(0, 10)} ($daysAgo days ago) by ${blame.author}');
            logger.warning(
                '    Commit: ${blame.hash.substring(0, 8)} - ${blame.message}');
          }
        }
      }
    }
  }

  Future<Map<String, AnalyticsDomain>> _loadDomains(
    String projectRoot,
    AnalyticsConfig config,
    Logger logger,
  ) async {
    // Resolve shared parameter paths
    final sharedParameterPaths = config.inputs.sharedParameters
        .map((p) => path.join(projectRoot, p))
        .toList();

    // Load files
    final loader = EventLoader(
      eventsPath: path.join(projectRoot, config.inputs.eventsPath),
      contextFiles:
          config.inputs.contexts.map((c) => path.join(projectRoot, c)).toList(),
      sharedParameterFiles: sharedParameterPaths,
      log: logger,
    );
    final eventSources = await loader.loadEventFiles();

    final Map<String, AnalyticsParameter> sharedParameters = {};
    if (sharedParameterPaths.isNotEmpty) {
      final sharedParser = YamlParser(
        log: logger,
        config: ParserConfig(naming: config.naming),
      );
      for (final sharedPath in sharedParameterPaths) {
        final sharedSource = await loader.loadSourceFile(sharedPath);
        if (sharedSource != null) {
          try {
            final params = sharedParser.parseSharedParameters(sharedSource);
            sharedParameters.addAll(params);
          } catch (_) {
            // Ignore errors here, just best effort
          }
        }
      }
    }

    final parser = YamlParser(
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
    return parser.parseEvents(eventSources);
  }
}

class _EventDefinition {
  _EventDefinition({
    required this.domainName,
    required this.eventName,
    required this.event,
  });
  final String domainName;
  final String eventName;
  final AnalyticsEvent event;
}

class _MethodInvocationVisitor extends RecursiveAstVisitor<void> {
  _MethodInvocationVisitor(this.targetMethodNames);
  final Set<String> targetMethodNames;
  final List<String> foundMethods = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (targetMethodNames.contains(node.methodName.name)) {
      foundMethods.add(node.methodName.name);
    }
    super.visitMethodInvocation(node);
  }
}
