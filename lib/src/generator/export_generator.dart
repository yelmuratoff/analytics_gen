import 'dart:io';

import 'package:path/path.dart' as path;

import '../config/analytics_config.dart';
import '../models/analytics_event.dart';
import '../util/logger.dart';
import 'export/csv_generator.dart';
import 'export/json_generator.dart';
import 'export/sql_generator.dart';
import 'export/sqlite_generator.dart';

/// Orchestrates export generation for analytics events.
///
/// Delegates to specialized generators for each format.
final class ExportGenerator {
  final AnalyticsConfig config;
  final String projectRoot;
  final Logger log;

  ExportGenerator({
    required this.config,
    required this.projectRoot,
    this.log = const NoOpLogger(),
  });

  /// Generates all configured export files
  Future<void> generate(Map<String, AnalyticsDomain> domains) async {
    log.info('Starting analytics export generation...');

    if (domains.isEmpty) {
      log.warning('No analytics events found. Skipping export generation.');
      return;
    }

    // Determine output directory
    final outputDir = config.exportsPath != null
        ? path.join(projectRoot, config.exportsPath!)
        : path.join(projectRoot, 'assets', 'generated');

    final outputDirectory = Directory(outputDir);
    if (!outputDirectory.existsSync()) {
      await outputDirectory.create(recursive: true);
    }

    // Clean up disabled exports
    if (!config.generateCsv) {
      final file = File(path.join(outputDir, 'analytics_events.csv'));
      if (file.existsSync()) await file.delete();
    }

    if (!config.generateJson) {
      final file = File(path.join(outputDir, 'analytics_events.json'));
      if (file.existsSync()) await file.delete();
      final minFile = File(path.join(outputDir, 'analytics_events.min.json'));
      if (minFile.existsSync()) await minFile.delete();
    }

    if (!config.generateSql) {
      final file = File(path.join(outputDir, 'create_database.sql'));
      if (file.existsSync()) await file.delete();
      final dbFile = File(path.join(outputDir, 'analytics_events.db'));
      if (dbFile.existsSync()) await dbFile.delete();
    }

    final tasks = <Future<void>>[];

    // Generate configured formats
    if (config.generateCsv) {
      tasks.add(() async {
        final csvGen = CsvGenerator(naming: config.naming);
        await csvGen.generate(
          domains,
          outputDir,
        );
        log.info(
          '✓ Generated CSVs at: $outputDir',
        );
      }());
    }

    if (config.generateJson) {
      tasks.add(() async {
        final jsonGen = JsonGenerator(naming: config.naming);
        await jsonGen.generate(domains, outputDir);
        log.info(
          '✓ Generated JSON at: ${path.join(outputDir, 'analytics_events.json')}',
        );
        log.debug(
          '✓ Generated minified JSON at: ${path.join(outputDir, 'analytics_events.min.json')}',
        );
      }());
    }

    if (config.generateSql) {
      tasks.add(() async {
        final sqlGen = SqlGenerator(naming: config.naming);
        final sqliteGen = SqliteGenerator(
          log: log,
          naming: config.naming,
        );

        final sqlPath = path.join(outputDir, 'create_database.sql');
        await sqlGen.generate(domains, sqlPath);
        log.info(
          '✓ Generated SQL at: $sqlPath',
        );

        // Try to generate SQLite database (optional)
        await sqliteGen.generate(
          domains,
          outputDir,
          existingSqlPath: sqlPath,
        );
      }());
    }

    await Future.wait(tasks);

    log.info('✓ Export generation completed');
  }
}
