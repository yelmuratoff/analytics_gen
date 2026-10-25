import 'dart:io';

import 'package:analytics_gen/src/cli/runner.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  group('AnalyticsGenRunner', () {
    late Directory project;

    void write(String relativePath, String content) {
      File(p.join(project.path, relativePath))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(content);
    }

    setUp(() {
      project = Directory.systemTemp.createTempSync('generate_runner_');
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
    parameters:
      method: string
  logout:
    description: User logs out
''');
    });

    tearDown(() => project.deleteSync(recursive: true));

    Future<({String output, int? exitCode})> run(List<String> arguments) {
      return runCliForTest(
        () => AnalyticsGenRunner(
          projectRoot: project.path,
          exitProcess: exitForTest,
        ).run(arguments),
      );
    }

    test('generates the Dart API into the configured directory', () async {
      final result = await run(const ['--no-verbose']);

      expect(result.exitCode, isNull);
      final generated =
          File(p.join(project.path, 'lib/analytics/events/auth_events.dart'));
      expect(generated.readAsStringSync(), contains('void logAuthLogin({'));
    });

    test('writes docs, exports and the Studio file when asked', () async {
      write('analytics_gen.yaml', '''
analytics_gen:
  inputs:
    events: events
  targets:
    json: true
''');

      final result = await run(
        const ['--no-code', '--docs', '--exports', '--studio', '--no-verbose'],
      );

      expect(result.exitCode, isNull);
      for (final generated in [
        'analytics_docs.md',
        'assets/generated/analytics_events.json',
        'analytics-studio.json',
      ]) {
        expect(
          File(p.join(project.path, generated)).existsSync(),
          isTrue,
          reason: generated,
        );
      }
      expect(Directory(p.join(project.path, 'lib')).existsSync(), isFalse);
    });

    test('generates only the docs with --no-code --docs', () async {
      write('analytics_gen.yaml', '''
analytics_gen:
  inputs:
    events: events
  outputs:
    docs: docs/plan.md
''');

      await run(const ['--no-code', '--docs', '--no-verbose']);

      expect(
        File(p.join(project.path, 'docs/plan.md')).readAsStringSync(),
        contains('auth'),
      );
    });

    test('says so when every target is turned off', () async {
      final result = await run(const ['--no-code']);

      expect(result.output, contains('No generation tasks were requested.'));
    });

    test('records first-seen dates in the tracking ledger', () async {
      write('analytics_gen.yaml', '''
analytics_gen:
  inputs:
    events: events
  outputs:
    dart: lib/analytics
  meta:
    auto_tracking_creation_date: true
''');

      final result = await run(const []);

      expect(
        result.output,
        contains('Tracking ledger: 2 events tracked (2 new)'),
      );
      final ledger = File(p.join(project.path, '.analytics_tracking.json'));
      expect(ledger.readAsStringSync(), contains('"auth.login"'));
    });

    test('prints the tracking plan with --plan', () async {
      final result = await run(const ['--plan', '--no-verbose']);

      expect(result.output, contains('Analytics Gen - Tracking Plan Overview'));
      expect(result.output, contains('Domains: 1 | Events: 2 | Parameters: 1'));
      expect(result.output, contains('Parameters: method (string)'));
    });

    test('validates without writing files with --validate-only', () async {
      final result = await run(const ['--validate-only', '--no-verbose']);

      expect(result.output, contains('✓ Validation successful.'));
      expect(result.output, contains('Events: 2'));
      expect(Directory(p.join(project.path, 'lib')).existsSync(), isFalse);
    });

    test('exits with 1 when --plan is combined with --watch', () async {
      final result = await run(const ['--plan', '--watch']);

      expect(result.exitCode, 1);
      expect(
        result.output,
        contains('--plan cannot be used together with --watch.'),
      );
    });

    test('reports an invalid tracking plan without a stack trace', () async {
      write('events/auth.yaml', 'auth:\n  login:\n    description: 42\n');

      final result = await run(const ['--validate-only']);

      expect(result.exitCode, 1);
      expect(result.output, contains('Field "description" must be a string.'));
      expect(result.output, isNot(contains('Stack trace')));
    });

    test('reports a missing events directory', () async {
      Directory(p.join(project.path, 'events')).deleteSync(recursive: true);

      final result = await run(const ['--plan', '--no-verbose']);

      expect(result.exitCode, isNull);
      expect(result.output, contains('No analytics events are defined yet.'));
    });
  });
}
