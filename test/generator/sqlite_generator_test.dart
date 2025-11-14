import 'dart:io';

import 'package:analytics_gen/src/generator/export/sqlite_generator.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

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

      final generator = SqliteGenerator(
        log: logs.add,
        runProcess: (executable, arguments) async {
          // Simulate missing sqlite3 for any command.
          return ProcessResult(0, 1, '', 'not found');
        },
      );

      await generator.generate(domains, tempDir.path);

      final sqlPath = p.join(tempDir.path, 'create_database.sql');
      final dbPath = p.join(tempDir.path, 'analytics_events.db');

      expect(File(sqlPath).existsSync(), isTrue);
      expect(File(dbPath).existsSync(), isFalse);
      expect(
        logs.join('\n'),
        contains('sqlite3 not found - skipping database file generation'),
      );
    });

    test('invokes sqlite3 when available and logs success', () async {
      final logs = <String>[];

      Future<ProcessResult> fakeRun(String executable, List<String> arguments) async {
        if (executable == 'which' && arguments.contains('sqlite3')) {
          return ProcessResult(0, 0, '/usr/bin/sqlite3', '');
        }

        if (executable == 'sqlite3') {
          final dbPath = arguments.first;
          // Simulate creation of the database file.
          File(dbPath).writeAsBytesSync(const <int>[]);
          return ProcessResult(0, 0, '', '');
        }

        return ProcessResult(0, 1, '', 'unexpected command');
      }

      final generator = SqliteGenerator(
        log: logs.add,
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
  });
}
