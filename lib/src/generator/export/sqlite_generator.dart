import 'dart:io';

import 'package:path/path.dart' as path;

import '../../config/naming_strategy.dart';
import '../../models/analytics_event.dart';
import '../../util/logger.dart';
import 'sql_generator.dart';

/// Generates SQLite database file from analytics events.
///
/// Creates a database file using sqlite3 command-line tool (must be installed).
final class SqliteGenerator {
  final SqlGenerator _sqlGenerator;
  final Logger log;
  final Future<ProcessResult> Function(
    String executable,
    List<String> arguments,
  ) _runProcess;

  SqliteGenerator({
    this.log = const NoOpLogger(),
    NamingStrategy? naming,
    Future<ProcessResult> Function(String, List<String>)? runProcess,
  })  : _sqlGenerator = SqlGenerator(naming: naming ?? const NamingStrategy()),
        _runProcess = runProcess ?? Process.run;

  /// Generates SQLite database file
  Future<void> generate(
    Map<String, AnalyticsDomain> domains,
    String outputDir, {
    String? existingSqlPath,
  }) async {
    final sqlPath =
        existingSqlPath ?? path.join(outputDir, 'create_database.sql');

    if (existingSqlPath == null) {
      await _sqlGenerator.generate(domains, sqlPath);
    }

    // Check if sqlite3 is available
    final sqliteAvailable = await _isSqlite3Available();

    if (!sqliteAvailable) {
      log.warning(
        '  ⚠ sqlite3 not found - skipping database file generation',
      );
      log.info('    SQL script created at: $sqlPath');
      log.info(
        '    To create database manually: sqlite3 analytics_events.db < create_database.sql',
      );
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
    final result = await _runProcess('sqlite3', [dbPath, '.read $sqlPath']);

    if (result.exitCode == 0) {
      log.info('✓ Generated SQLite database at: $dbPath');
    } else {
      log.error('  ⚠ Failed to create database: ${result.stderr}');
      log.info('    SQL script available at: $sqlPath');
    }
  }

  /// Checks if sqlite3 command is available
  Future<bool> _isSqlite3Available() async {
    try {
      final result = await _runProcess('sqlite3', ['--version']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}
