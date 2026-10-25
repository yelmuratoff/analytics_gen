import 'dart:io';

import 'package:analytics_gen/src/config/naming_strategy.dart';
import 'package:analytics_gen/src/core/exceptions.dart';
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
        projectRoot: tempDir.path,
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
        projectRoot: tempDir.path,
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

    test('passes the script path to sqlite3 as one quoted argument', () async {
      final outputDir = p.join(tempDir.path, r'my "exports" \ dir');
      Directory(outputDir).createSync();
      final calls = <List<String>>[];

      final generator = SqliteGenerator(
        projectRoot: tempDir.path,
        runProcess: (executable, arguments) async {
          calls.add(arguments);
          return ProcessResult(0, 0, '', '');
        },
      );

      await generator.generate(domains, outputDir);

      final sqlPath = p.join(outputDir, 'create_database.sql');
      final escaped = sqlPath.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
      expect(calls.last, [
        p.join(outputDir, 'analytics_events.db'),
        '.read "$escaped"',
      ]);
    });

    test('builds the database with sqlite3 in a directory with spaces',
        () async {
      final outputDir = p.join(tempDir.path, "o'neil exports");
      Directory(outputDir).createSync();

      await SqliteGenerator(projectRoot: tempDir.path)
          .generate(domains, outputDir);

      final tables = Process.runSync(
        'sqlite3',
        [p.join(outputDir, 'analytics_events.db'), '.tables'],
      );
      expect(
        (tables.stdout as String).split(RegExp(r'\s+')),
        containsAll(['domains', 'events', 'parameters']),
      );
    }, skip: _sqlite3Missing() ? 'sqlite3 is not installed' : false);

    test('deletes stale database and throws when sqlite3 errors', () async {
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
        projectRoot: tempDir.path,
        naming: const NamingStrategy(),
        runProcess: fakeRun,
      );

      await expectLater(
        generator.generate(domains, tempDir.path),
        throwsA(
          isA<AnalyticsGenerationException>()
              .having(
                (e) => e.message,
                'message',
                'sqlite3 could not build $dbPath: creation failed',
              )
              .having(
                (e) => e.sourcePath,
                'sourcePath',
                p.join(tempDir.path, 'create_database.sql'),
              ),
        ),
      );
      expect(File(dbPath).existsSync(), isFalse);
    });
  });
}

bool _sqlite3Missing() {
  try {
    return Process.runSync('sqlite3', ['--version']).exitCode != 0;
  } on ProcessException {
    return true;
  }
}
