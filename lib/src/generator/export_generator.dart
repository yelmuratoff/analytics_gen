import 'dart:io';

import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:path/path.dart' as path;

import '../config/analytics_config.dart';
import '../util/logger.dart';
import 'export/csv_generator.dart';
import 'export/json_generator.dart';
import 'export/sql_generator.dart';
import 'export/sqlite_generator.dart';

/// Orchestrates export generation for analytics events.
///
/// Delegates to specialized generators for each format.
final class ExportGenerator {
  /// Creates a new export generator.
  ExportGenerator({
    required this.config,
    required this.projectRoot,
    this.log = const NoOpLogger(),
  });

  /// The analytics configuration.
  final AnalyticsConfig config;

  /// The root directory of the project.
  final String projectRoot;

  /// The logger to use.
  final Logger log;

  /// Generates all configured export files
  Future<void> generate(Map<String, AnalyticsDomain> domains) async {
    log.info('Starting analytics export generation...');

    if (domains.isEmpty) {
      log.warning('No analytics events found. Skipping export generation.');
      return;
    }

    // Determine output directory
    final outputDir = config.outputs.exportsPath != null
        ? path.join(projectRoot, config.outputs.exportsPath!)
        : path.join(projectRoot, 'assets', 'generated');

    final outputDirectory = Directory(outputDir);
    if (!outputDirectory.existsSync()) {
      await outputDirectory.create(recursive: true);
    }

    // Clean up disabled exports
    if (!config.targets.generateCsv) {
      final csvFiles = [
        'analytics_events.csv',
        'analytics_parameters.csv',
        'analytics_metadata.csv',
        'analytics_event_parameters.csv',
        'analytics_master.csv',
        'analytics_domains.csv',
      ];
      for (final fileName in csvFiles) {
        final file = File(path.join(outputDir, fileName));
        if (file.existsSync()) await file.delete();
      }
    }

    if (!config.targets.generateJson) {
      final file = File(path.join(outputDir, 'analytics_events.json'));
      if (file.existsSync()) await file.delete();
      final minFile = File(path.join(outputDir, 'analytics_events.min.json'));
      if (minFile.existsSync()) await minFile.delete();
    }

    if (!config.targets.generateSql) {
      final file = File(path.join(outputDir, 'create_database.sql'));
      if (file.existsSync()) await file.delete();
      final dbFile = File(path.join(outputDir, 'analytics_events.db'));
      if (dbFile.existsSync()) await dbFile.delete();
    }

    final tasks = <Future<void>>[];

    // Generate configured formats
    if (config.targets.generateCsv) {
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

    if (config.targets.generateJson) {
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

    if (config.targets.generateSql) {
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
