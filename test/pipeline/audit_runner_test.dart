import 'dart:io';

import 'package:analytics_gen/src/pipeline/audit_runner.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  group('audit CLI', () {
    late Directory projectDir;

    setUp(() {
      projectDir = Directory.systemTemp.createTempSync('audit_runner_');
      void write(String relativePath, String content) =>
          File(p.join(projectDir.path, relativePath))
            ..createSync(recursive: true)
            ..writeAsStringSync(content);

      write('pubspec.yaml', '''
name: audit_fixture
environment:
  sdk: ">=3.4.0 <4.0.0"
dependencies:
  analytics_gen:
    path: ${Directory.current.absolute.path}
''');
      write('analytics_gen.yaml', '''
analytics_gen:
  inputs:
    events: events
    shared_parameters:
      - shared/shared.yaml
''');
      write('events/auth.yaml', 'auth:\n  login:\n    description: Login\n');
      write('shared/shared.yaml', 'parameters:\n  user_id: [\n');
      write('lib/main.dart', 'void main() {}\n');
    });

    tearDown(() => projectDir.deleteSync(recursive: true));

    test('fails on a broken shared parameters file like generation does',
        () async {
      final pubGet = await Process.run(
        Platform.executable,
        ['pub', 'get', '--offline'],
        workingDirectory: projectDir.path,
      );
      expect(pubGet.exitCode, 0, reason: '${pubGet.stdout}${pubGet.stderr}');

      final audit = await Process.run(
        Platform.executable,
        ['run', 'analytics_gen:audit'],
        workingDirectory: projectDir.path,
      );

      expect(audit.exitCode, 1, reason: '${audit.stdout}${audit.stderr}');
      expect('${audit.stdout}${audit.stderr}', contains('shared.yaml'));
    });
  });

  group('AuditRunner in process', () {
    late Directory project;

    void write(String relativePath, String content) {
      File(p.join(project.path, relativePath))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(content);
    }

    setUp(() {
      project = Directory.systemTemp.createTempSync('audit_in_process_');
      write('analytics_gen.yaml', '''
analytics_gen:
  inputs:
    events: events
  outputs:
    dart: lib/analytics
''');
      write('events/auth.yaml', '''
auth:
  login:
    description: User logs in
  logout:
    description: User logs out
''');
    });

    tearDown(() => project.deleteSync(recursive: true));

    Future<({String output, int? exitCode})> audit() => runCliForTest(
          () => AuditRunner(
            projectRoot: project.path,
            exitProcess: exitForTest,
          ).run(const ['--no-verbose']),
        );

    test('lists the events no code logs, with where they are defined',
        () async {
      write('lib/app.dart', 'void track(dynamic a) => a.logAuthLogin();\n');

      final result = await audit();

      expect(result.exitCode, isNull);
      expect(result.output, contains('Found 1 dead events (0 usages):'));
      expect(
        result.output,
        contains('auth.logout (Method: logAuthLogout)'),
      );
      expect(result.output, contains('Defined in: events/auth.yaml:'));
    });

    test('ignores calls inside the generated code directory', () async {
      write('lib/app.dart', 'void track(dynamic a) => a.logAuthLogin();\n');
      write(
        'lib/analytics/generated.dart',
        'void f(dynamic a) => a.logAuthLogout();\n',
      );

      final result = await audit();

      expect(result.output, contains('auth.logout (Method: logAuthLogout)'));
    });

    test('reports when every event is logged', () async {
      write(
        'lib/app.dart',
        'void track(dynamic a) {\n'
            '  a.logAuthLogin();\n'
            '  a.logAuthLogout();\n'
            '}\n',
      );

      final result = await audit();

      expect(result.output, contains('✓ All 2 events are used.'));
    });

    test('exits with 1 and names the path when lib/ is missing', () async {
      final result = await audit();

      expect(result.exitCode, 1);
      expect(result.output, contains('lib directory not found'));
      expect(result.output, isNot(contains('Stack trace')));
    });

    test('warns when the tracking plan has no events', () async {
      Directory(p.join(project.path, 'events')).deleteSync(recursive: true);
      write('events/.keep', '');

      final result = await audit();

      expect(result.output, contains('No events found in definition files.'));
    });
  });
}
