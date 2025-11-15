import 'dart:io';

import 'package:path/path.dart' as path;

import '../config/analytics_config.dart';
import '../parser/yaml_parser.dart';
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
  final void Function(String message)? log;

  ExportGenerator({
    required this.config,
    required this.projectRoot,
    this.log,
  });

  /// Generates all configured export files
  Future<void> generate() async {
    log?.call('Starting analytics export generation...');

    // Parse YAML files
    final parser = YamlParser(
      eventsPath: path.join(projectRoot, config.eventsPath),
      log: log,
    );
    final domains = await parser.parseEvents();

    if (domains.isEmpty) {
      log?.call('No analytics events found. Skipping export generation.');
      return;
    }

    // Determine output directory
    final outputDir = config.exportsPath != null
        ? path.join(projectRoot, config.exportsPath!)
        : path.join(projectRoot, 'assets', 'generated');

    final outputDirectory = Directory(outputDir);
    if (outputDirectory.existsSync()) {
      await outputDirectory.delete(recursive: true);
    }
    await outputDirectory.create(recursive: true);

    // Generate configured formats
    if (config.generateCsv) {
      final csvGen = CsvGenerator();
      await csvGen.generate(
        domains,
        path.join(outputDir, 'analytics_events.csv'),
      );
      log?.call(
        '✓ Generated CSV at: ${path.join(outputDir, 'analytics_events.csv')}',
      );
    }

    if (config.generateJson) {
      final jsonGen = JsonGenerator();
      await jsonGen.generate(domains, outputDir);
      log?.call(
        '✓ Generated JSON at: ${path.join(outputDir, 'analytics_events.json')}',
      );
      log?.call(
        '✓ Generated minified JSON at: ${path.join(outputDir, 'analytics_events.min.json')}',
      );
    }

    if (config.generateSql) {
      final sqlGen = SqlGenerator();
      final sqliteGen = SqliteGenerator(log: log);

      final sqlPath = path.join(outputDir, 'create_database.sql');
      await sqlGen.generate(domains, sqlPath);
      log?.call(
        '✓ Generated SQL at: $sqlPath',
      );

      // Try to generate SQLite database (optional)
      await sqliteGen.generate(
        domains,
        outputDir,
        existingSqlPath: sqlPath,
      );
    }

    log?.call('✓ Export generation completed');
  }
}
