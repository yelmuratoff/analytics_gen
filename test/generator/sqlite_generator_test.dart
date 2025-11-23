import 'dart:io';

import 'package:analytics_gen/src/config/naming_strategy.dart';
import 'package:analytics_gen/src/generator/export/sqlite_generator.dart';
import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  group('SqliteGenerator', () {
    late Directory tempDir;
    late Map<String, AnalyticsDomain> domains;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('analytics_gen_sqlite_');
      domains = <String, AnalyticsDomain>{
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [
            const AnalyticsEvent(
              name: 'login',
              description: 'User logs in',
              parameters: [
                AnalyticsParameter(
                  name: 'method',
                  type: 'string',
                  isNullable: false,
                ),
              ],
            ),
          ],
        ),
      };
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('skips database creation when sqlite3 is not available', () async {
      final logs = <String>[];
      final sqlPath = p.join(tempDir.path, 'create_database.sql');
      File(sqlPath).writeAsStringSync('prebuilt');

      final generator = SqliteGenerator(
        log: TestLogger(logs),
        naming: const NamingStrategy(),
        runProcess: (executable, arguments) async {
          if (executable == 'sqlite3' && arguments.contains('--version')) {
            return ProcessResult(0, 1, '', 'not found');
          }
          return ProcessResult(0, 0, '', '');
        },
      );

      await generator.generate(
        domains,
        tempDir.path,
        existingSqlPath: sqlPath,
      );

      final dbPath = p.join(tempDir.path, 'analytics_events.db');

      expect(File(sqlPath).existsSync(), isTrue);
      expect(File(sqlPath).readAsStringSync(), equals('prebuilt'));
      expect(File(dbPath).existsSync(), isFalse);
      expect(
        logs.join('\n'),
        contains('sqlite3 not found - skipping database file generation'),
      );
    });

    test('invokes sqlite3 when available and logs success', () async {
      final logs = <String>[];

      Future<ProcessResult> fakeRun(
        String executable,
        List<String> arguments,
      ) async {
        if (executable == 'sqlite3' &&
            arguments.length == 1 &&
            arguments[0] == '--version') {
          return ProcessResult(0, 0, '3.45.0', '');
        }

        if (executable == 'sqlite3' && arguments.length == 2) {
          final dbPath = arguments.first;
          // Simulate creation of the database file when executing the SQL script.
          File(dbPath).writeAsBytesSync(const <int>[]);
          return ProcessResult(0, 0, '', '');
        }

        return ProcessResult(0, 1, '', 'unexpected command');
      }

      final generator = SqliteGenerator(
        log: TestLogger(logs),
        naming: const NamingStrategy(),
        runProcess: fakeRun,
      );

      await generator.generate(domains, tempDir.path);

      final dbPath = p.join(tempDir.path, 'analytics_events.db');

      expect(File(dbPath).existsSync(), isTrue);
      expect(
        logs.join('\n'),
        contains('✓ Generated SQLite database at: $dbPath'),
      );
    });

    test('deletes stale database and logs failure when sqlite3 errors',
        () async {
      final logs = <String>[];
      final dbPath = p.join(tempDir.path, 'analytics_events.db');
      File(dbPath).writeAsStringSync('stale content');

      Future<ProcessResult> fakeRun(
        String executable,
        List<String> arguments,
      ) async {
        if (executable == 'sqlite3' &&
            arguments.length == 1 &&
            arguments[0] == '--version') {
          return ProcessResult(0, 0, '3.45.0', '');
        }

        if (executable == 'sqlite3' && arguments.length == 2) {
          return ProcessResult(0, 1, '', 'creation failed');
        }

        return ProcessResult(0, 1, '', 'unexpected command');
      }

      final generator = SqliteGenerator(
        log: TestLogger(logs),
        naming: const NamingStrategy(),
        runProcess: fakeRun,
      );

      await generator.generate(domains, tempDir.path);

      expect(File(dbPath).existsSync(), isFalse);
      final logOutput = logs.join('\n');
      expect(
        logOutput,
        contains('⚠ Failed to create database: creation failed'),
      );
      expect(logOutput, contains('SQL script available at:'));
    });
  });
}
