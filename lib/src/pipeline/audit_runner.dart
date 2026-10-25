import 'dart:io';

import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/config/config_parser.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:analytics_gen/src/pipeline/tracking_plan_loader.dart';
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
import '../cli/cli_command.dart';
import '../cli/usage.dart';
import '../services/git_service.dart';

/// Runner for the dead event audit tool.
class AuditRunner {
  /// Creates a new audit runner.
  AuditRunner({
    ArgParser? parser,
    ConfigParser? configParser,
  })  : _parser = parser ?? createAuditArgParser(),
        _configParser = configParser;

  final ArgParser _parser;
  final ConfigParser? _configParser;

  /// Runs the audit.
  Future<void> run(List<String> arguments) => runCliCommand(
        arguments,
        parser: _parser,
        printUsage: (logger) => printAuditUsage(_parser, logger: logger),
        configParser: _configParser,
        command: (invocation) => _runAudit(
          invocation.projectRoot,
          invocation.config,
          invocation.logger,
        ),
      );

  Future<void> _runAudit(
    String projectRoot,
    AnalyticsConfig config,
    Logger logger,
  ) async {
    logger.info('Starting "Dead Event" Audit...');

    // 1. Load Defined Events
    final plan =
        await TrackingPlanLoader(projectRoot: projectRoot, config: config)
            .load(logger);
    final domains = plan.domains;
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

    logger.info('Scanning codebase including: $libPath');

    final generatedDir = path.join(projectRoot, config.outputs.dartPath);

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
        if (path.isWithin(generatedDir, filePath)) {
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
