import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

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
}
