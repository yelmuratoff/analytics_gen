import 'dart:io';

import 'package:path/path.dart' as path;

import '../config/analytics_config.dart';
import '../models/analytics_event.dart';
import '../util/file_utils.dart';
import 'generation_metadata.dart';
import 'generation_telemetry.dart';
import 'renderers/analytics_class_renderer.dart';
import 'renderers/context_renderer.dart';
import 'renderers/event_renderer.dart';

/// Generates Dart code for analytics events from YAML configuration.
final class CodeGenerator {
  final AnalyticsConfig config;
  final String projectRoot;
  final void Function(String message)? log;
  final GenerationTelemetry _telemetry;

  final AnalyticsClassRenderer _classRenderer;
  final ContextRenderer _contextRenderer;
  final EventRenderer _eventRenderer;

  CodeGenerator({
    required this.config,
    required this.projectRoot,
    this.log,
    GenerationTelemetry? telemetry,
    AnalyticsClassRenderer? classRenderer,
    ContextRenderer? contextRenderer,
    EventRenderer? eventRenderer,
  })  : _telemetry = telemetry ??
            (log != null ? LoggingTelemetry(log) : const NoOpTelemetry()),
        _classRenderer = classRenderer ?? AnalyticsClassRenderer(config),
        _contextRenderer = contextRenderer ?? const ContextRenderer(),
        _eventRenderer = eventRenderer ?? EventRenderer(config);

  /// Generates analytics code and writes to configured output path
  Future<void> generate(
    Map<String, AnalyticsDomain> domains, {
    Map<String, List<AnalyticsParameter>> contexts = const {},
  }) async {
    final startTime = DateTime.now();

    // Filter out empty contexts to avoid generating empty files
    final activeContexts = Map<String, List<AnalyticsParameter>>.from(contexts)
      ..removeWhere((_, value) => value.isEmpty);

    if (domains.isEmpty && activeContexts.isEmpty) {
      log?.call(
          'No analytics events or properties found. Skipping generation.');
      return;
    }

    final totalEvents = domains.values.fold(0, (sum, d) => sum + d.eventCount);
    final totalParams =
        domains.values.fold(0, (sum, d) => sum + d.parameterCount);

    final context = GenerationContext(
      domainCount: domains.length,
      contextCount: activeContexts.length,
      totalEventCount: totalEvents,
      totalParameterCount: totalParams,
      generateDocs: true,
      generateExports: true,
      generateCode: true,
    );

    _telemetry.onGenerationStart(context);
    log?.call('Starting analytics code generation...');

    final outputDir = path.join(projectRoot, 'lib', config.outputPath);
    final eventsDir = path.join(outputDir, 'events');
    final contextsDir = path.join(outputDir, 'contexts');

    // Ensure output directories exist
    await _prepareOutputDirectories(outputDir, eventsDir, contextsDir);

    // Track generated files to clean up stale ones later
    final generatedFiles = <String>{};

    // Generate individual domain files with telemetry
    await Future.wait(domains.entries.map((entry) async {
      final domainStartTime = DateTime.now();
      final filePath =
          await _generateDomainFile(entry.key, entry.value, eventsDir);
      generatedFiles.add(filePath);

      final domainElapsed = DateTime.now().difference(domainStartTime);
      _telemetry.onDomainProcessed(
        entry.key,
        domainElapsed,
        entry.value.eventCount,
      );
    }));

    // Generate context files with telemetry
    for (final entry in activeContexts.entries) {
      final contextStartTime = DateTime.now();
      await _generateContextFile(entry.key, entry.value, contextsDir);

      final contextElapsed = DateTime.now().difference(contextStartTime);
      _telemetry.onContextProcessed(
        entry.key,
        contextElapsed,
        entry.value.length,
      );
    }

    // Clean up stale files
    await _cleanStaleFiles(eventsDir, generatedFiles);

    // Generate barrel file with all exports
    await _generateBarrelFile(domains, outputDir);

    log?.call('✓ Generated ${domains.length} domain files');
    log?.call('  Domains: ${domains.keys.join(', ')}');

    // Generate Analytics singleton class
    await _generateAnalyticsClass(
      domains,
      contexts: activeContexts,
    );

    final elapsed = DateTime.now().difference(startTime);
    final filesGenerated = generatedFiles.length +
        activeContexts.length +
        2; // +2 for barrel and analytics
    _telemetry.onGenerationComplete(elapsed, filesGenerated);
  }

  Future<String> _generateContextFile(
    String contextName,
    List<AnalyticsParameter> properties,
    String outputDir,
  ) async {
    final content = _contextRenderer.renderContextFile(contextName, properties);

    final fileName = '${contextName}_context.dart';
    final filePath = path.join(outputDir, fileName);
    await _writeFileIfContentChanged(filePath, content);
    return filePath;
  }

  /// Generates a separate file for a single domain and returns the file path
  Future<String> _generateDomainFile(
    String domainName,
    AnalyticsDomain domain,
    String eventsDir,
  ) async {
    final content = _eventRenderer.renderDomainFile(domainName, domain);

    final fileName = '${domainName}_events.dart';
    final filePath = path.join(eventsDir, fileName);
    await _writeFileIfContentChanged(filePath, content);
    return filePath;
  }

  /// Generates barrel file that exports all domain event files
  Future<void> _generateBarrelFile(
    Map<String, AnalyticsDomain> domains,
    String outputDir,
  ) async {
    final buffer = StringBuffer();

    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// Barrel file - exports all domain event files');
    buffer.writeln();

    // Export all domain files
    for (final domainName in domains.keys.toList()..sort()) {
      buffer.writeln("export 'events/${domainName}_events.dart';");
    }

    final barrelPath = path.join(outputDir, 'generated_events.dart');
    await _writeFileIfContentChanged(barrelPath, buffer.toString());
  }

  /// Generates Analytics singleton class with all domain mixins
  Future<void> _generateAnalyticsClass(
    Map<String, AnalyticsDomain> domains, {
    Map<String, List<AnalyticsParameter>> contexts = const {},
  }) async {
    final metadata = GenerationMetadata.fromDomains(domains);
    final content = _classRenderer.renderAnalyticsClass(
      domains,
      contexts: contexts,
      planFingerprint: metadata.fingerprint,
    );

    // Write to file
    final analyticsPath = path.join(
      projectRoot,
      'lib',
      config.outputPath,
      'analytics.dart',
    );
    await _writeFileIfContentChanged(analyticsPath, content);

    log?.call('✓ Generated Analytics class at: $analyticsPath');
  }

  /// Writes a file only if its contents differ from the existing file.
  ///
  /// This avoids touching modified times and prevents unnecessary git
  /// diffs when regenerating code with no changes.
  Future<void> _writeFileIfContentChanged(
      String filePath, String contents) async {
    await writeFileIfContentChanged(filePath, contents);
  }

  /// Removes stale generated files so deleted domains do not linger.
  Future<void> _prepareOutputDirectories(
    String outputDir,
    String eventsDir,
    String contextsDir,
  ) async {
    final outputDirectory = Directory(outputDir);
    if (!outputDirectory.existsSync()) {
      await outputDirectory.create(recursive: true);
    }

    final eventsDirectory = Directory(eventsDir);
    if (!eventsDirectory.existsSync()) {
      await eventsDirectory.create(recursive: true);
    }

    final contextsDirectory = Directory(contextsDir);
    if (!contextsDirectory.existsSync()) {
      await contextsDirectory.create(recursive: true);
    }
  }

  Future<void> _cleanStaleFiles(
    String eventsDir,
    Set<String> generatedFiles,
  ) async {
    final dir = Directory(eventsDir);
    if (!dir.existsSync()) return;

    await for (final entity in dir.list()) {
      if (entity is File && !generatedFiles.contains(entity.path)) {
        await entity.delete();
      }
    }
  }
}
