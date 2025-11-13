import 'dart:io';

import 'package:path/path.dart' as path;

import '../../models/analytics_event.dart';
import 'sql_generator.dart';

/// Generates SQLite database file from analytics events.
///
/// Creates a database file using sqlite3 command-line tool (must be installed).
final class SqliteGenerator {
  final SqlGenerator _sqlGenerator = SqlGenerator();

  /// Generates SQLite database file
  Future<void> generate(
    Map<String, AnalyticsDomain> domains,
    String outputDir,
  ) async {
    // First generate SQL script
    final sqlPath = path.join(outputDir, 'create_database.sql');
    await _sqlGenerator.generate(domains, sqlPath);

    // Check if sqlite3 is available
    final sqliteAvailable = await _isSqlite3Available();

    if (!sqliteAvailable) {
      print(
        '  ⚠ sqlite3 not found - skipping database file generation',
      );
      print('    SQL script created at: $sqlPath');
      print('    To create database manually: sqlite3 analytics_events.db < create_database.sql');
      return;
    }

    // Create database file using sqlite3
    final dbPath = path.join(outputDir, 'analytics_events.db');

    // Remove existing database
    final dbFile = File(dbPath);
    if (dbFile.existsSync()) {
      await dbFile.delete();
    }

    // Execute SQL script to create database
    final result = await Process.run(
      'sqlite3',
      [dbPath, '.read $sqlPath'],
    );

    if (result.exitCode == 0) {
      print('✓ Generated SQLite database at: $dbPath');
    } else {
      print('  ⚠ Failed to create database: ${result.stderr}');
      print('    SQL script available at: $sqlPath');
    }
  }

  /// Checks if sqlite3 command is available
  Future<bool> _isSqlite3Available() async {
    try {
      final result = await Process.run('which', ['sqlite3']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
}
