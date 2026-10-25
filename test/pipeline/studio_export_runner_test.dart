import 'dart:convert';
import 'dart:io';

import 'package:analytics_gen/src/pipeline/studio_export_runner.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../test_utils.dart';

/// We test studio_export by running the actual CLI command from the project root
/// against fixture YAML files created in a temp directory, then verifying the
/// generated JSON output.
///
/// This is an integration test because the runner reads raw YAML files, not
/// parsed models — so unit testing internal methods offers little value.

/// Ensures example/ has resolved deps. Skips test if Flutter is unavailable.
bool _ensureExampleDeps(String exampleDir) {
  final configFile =
      File(p.join(exampleDir, '.dart_tool', 'package_config.json'));
  if (configFile.existsSync()) return true;
  try {
    final result = Process.runSync('flutter', ['pub', 'get'],
        workingDirectory: exampleDir);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}

void main() {
  group('studio_export CLI', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('studio_export_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('exports the example project correctly', () {
      // Use the real example/ directory
      final projectRoot = Directory.current.path;
      final exampleDir = p.join(projectRoot, 'example');
      final outputPath = p.join(tempDir.path, 'example-export.json');

      if (!_ensureExampleDeps(exampleDir)) {
        markTestSkipped('Flutter SDK not available');
        return;
      }

      final result = Process.runSync(
        Platform.executable,
        [
          'run',
          'analytics_gen:studio_export',
          '-o',
          outputPath,
          '--no-verbose',
        ],
        workingDirectory: exampleDir,
      );

      expect(result.exitCode, 0,
          reason: 'stderr: ${result.stderr}\nstdout: ${result.stdout}');

      final json = jsonDecode(File(outputPath).readAsStringSync())
          as Map<String, dynamic>;

      // Top-level structure
      expect(json['version'], 1);
      expect(json['activeTab'], 'config');
      expect(json['config'], isA<Map>());
      expect(json['eventFiles'], isA<List>());
      expect(json['sharedParamFiles'], isA<List>());
      expect(json['contextFiles'], isA<List>());

      // Metadata block carries a content revision for CI comparison.
      expect(json['meta'], isA<Map>());
      expect((json['meta'] as Map)['revision'], isA<String>());

      // Config
      final config = json['config'] as Map<String, dynamic>;
      expect(config['inputs']['events'], 'events');
      expect(config['outputs']['dart'], 'lib/src/analytics/generated');
      expect(config['targets']['plan'], true);
      expect(config['naming']['domain_aliases'], isA<Map>());

      // No flat aliases leaked through
      expect(config.keys.every((k) {
        final val = config[k];
        return val is Map;
      }), true,
          reason:
              'All config top-level values should be Maps (sections), not scalar aliases');

      // Event files
      final eventFiles = json['eventFiles'] as List;
      expect(eventFiles.length, greaterThanOrEqualTo(1));
      final authFile = eventFiles.firstWhere(
        (f) => (f as Map)['fileName'] == 'auth.yaml',
        orElse: () => fail('auth.yaml not found in eventFiles'),
      ) as Map<String, dynamic>;

      final authDomain = authFile['domains']['auth'] as Map<String, dynamic>;
      expect(authDomain, isNotEmpty);

      // Verify shared param ref is null
      final loginV2 = authDomain['login_v2'] as Map<String, dynamic>;
      expect(loginV2['parameters']['session_id'], isNull,
          reason: 'Shared param reference should be null');

      // Verify shorthand param
      final signup = authDomain['signup'] as Map<String, dynamic>;
      expect(signup['parameters']['method'], 'string',
          reason: 'Shorthand param should be a string');

      // Verify full param object
      final loginMethod = (authDomain['login'] as Map)['parameters']['method'];
      expect(loginMethod, isA<Map>());
      expect(loginMethod['type'], 'string');

      // Verify dart_type param
      final verifyUser = authDomain['verify_user'] as Map<String, dynamic>;
      expect(verifyUser['parameters']['status']['dart_type'],
          'VerificationStatus');

      // Shared param files
      final sharedFiles = json['sharedParamFiles'] as List;
      expect(sharedFiles.length, greaterThanOrEqualTo(1));
      final sharedUser = sharedFiles.firstWhere(
        (f) => (f as Map)['fileName'] == 'shared_user.yaml',
        orElse: () => fail('shared_user.yaml not found'),
      ) as Map<String, dynamic>;
      expect(sharedUser['parameters']['session_id'], isA<Map>());

      // Context files
      final contextFiles = json['contextFiles'] as List;
      expect(contextFiles.length, greaterThanOrEqualTo(1));
      final userProps = contextFiles.firstWhere(
        (f) => (f as Map)['contextName'] == 'user_properties',
        orElse: () => fail('user_properties context not found'),
      ) as Map<String, dynamic>;
      expect(userProps['properties']['login_count']['operations'],
          contains('increment'));
    });

    test('event files exclude shared and context files', () {
      final projectRoot = Directory.current.path;
      final exampleDir = p.join(projectRoot, 'example');
      final outputPath = p.join(tempDir.path, 'exclude-test.json');

      if (!_ensureExampleDeps(exampleDir)) {
        markTestSkipped('Flutter SDK not available');
        return;
      }

      final result = Process.runSync(
        Platform.executable,
        [
          'run',
          'analytics_gen:studio_export',
          '-o',
          outputPath,
          '--no-verbose'
        ],
        workingDirectory: exampleDir,
      );
      expect(result.exitCode, 0);

      final json = jsonDecode(File(outputPath).readAsStringSync())
          as Map<String, dynamic>;

      final eventFileNames = (json['eventFiles'] as List)
          .map((f) => (f as Map)['fileName'] as String)
          .toSet();
      final sharedFileNames = (json['sharedParamFiles'] as List)
          .map((f) => (f as Map)['fileName'] as String)
          .toSet();
      final contextFileNames = (json['contextFiles'] as List)
          .map((f) => (f as Map)['fileName'] as String)
          .toSet();

      // No overlap between event files and shared/context files
      expect(eventFileNames.intersection(sharedFileNames), isEmpty);
      expect(eventFileNames.intersection(contextFileNames), isEmpty);
    });

    test('--help exits cleanly', () {
      final result = Process.runSync(
        Platform.executable,
        ['run', 'analytics_gen:studio_export', '--help'],
        workingDirectory: Directory.current.path,
      );
      expect(result.exitCode, 0);
      expect(result.stdout.toString(), contains('studio_export'));
    });
  });

  group('StudioExportRunner in process', () {
    late Directory project;

    setUp(() {
      project = Directory.systemTemp.createTempSync('studio_in_process_');
      File(p.join(project.path, 'analytics_gen.yaml'))
          .writeAsStringSync('analytics_gen:\n  inputs:\n    events: events\n');
      File(p.join(project.path, 'events/auth.yaml'))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('auth:\n  login:\n    description: Login\n');
    });

    tearDown(() => project.deleteSync(recursive: true));

    Future<({String output, int? exitCode})> export(List<String> args) =>
        runCliForTest(
          () => StudioExportRunner(
            projectRoot: project.path,
            exitProcess: exitForTest,
          ).run(args),
        );

    test('writes the project file to --output', () async {
      final result = await export(const ['-o', 'studio/out.json']);

      final file = File(p.join(project.path, 'studio/out.json'));
      expect(result.exitCode, isNull);
      expect(result.output, contains('Exported: ${file.path}'));
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(json['eventFiles'], hasLength(1));
    });

    test('exits with 1 when the config file cannot be read', () async {
      File(p.join(project.path, 'analytics_gen.yaml'))
          .writeAsStringSync('- not a map\n');

      final result = await export(const []);

      expect(result.exitCode, 1);
      expect(result.output, contains('expected a map but got a list'));
    });
  });
}
