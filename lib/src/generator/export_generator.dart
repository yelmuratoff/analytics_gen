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

  ExportGenerator({
    required this.config,
    required this.projectRoot,
  });

  /// Generates all configured export files
  Future<void> generate() async {
    print('Starting analytics export generation...');

    // Parse YAML files
    final parser = YamlParser(
      eventsPath: path.join(projectRoot, config.eventsPath),
    );
    final domains = await parser.parseEvents();

    if (domains.isEmpty) {
      print('No analytics events found. Skipping export generation.');
      return;
    }

    // Determine output directory
    final outputDir = config.exportsPath != null
        ? path.join(projectRoot, config.exportsPath!)
        : path.join(projectRoot, 'assets', 'generated');

    final outputDirectory = Directory(outputDir);
    await outputDirectory.create(recursive: true);

    // Generate configured formats
    if (config.generateCsv) {
      final csvGen = CsvGenerator();
      await csvGen.generate(
        domains,
        path.join(outputDir, 'analytics_events.csv'),
      );
      print('✓ Generated CSV at: ${path.join(outputDir, 'analytics_events.csv')}');
    }

    if (config.generateJson) {
      final jsonGen = JsonGenerator();
      await jsonGen.generate(domains, outputDir);
      print('✓ Generated JSON at: ${path.join(outputDir, 'analytics_events.json')}');
      print('✓ Generated minified JSON at: ${path.join(outputDir, 'analytics_events.min.json')}');
    }

    if (config.generateSql) {
      final sqlGen = SqlGenerator();
      final sqliteGen = SqliteGenerator();

      await sqlGen.generate(
        domains,
        path.join(outputDir, 'create_database.sql'),
      );
      print('✓ Generated SQL at: ${path.join(outputDir, 'create_database.sql')}');

      // Try to generate SQLite database (optional)
      await sqliteGen.generate(domains, outputDir);
    }

    print('✓ Export generation completed');
  }
}
