import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// We test studio_export by running the actual CLI command from the project root
/// against fixture YAML files created in a temp directory, then verifying the
/// generated JSON output.
///
/// This is an integration test because the runner reads raw YAML files, not
/// parsed models — so unit testing internal methods offers little value.
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

      // Ensure example deps are resolved (Flutter project needs flutter pub get)
      if (!File(p.join(exampleDir, '.dart_tool', 'package_config.json'))
          .existsSync()) {
        final pubGet = Process.runSync('flutter', ['pub', 'get'],
            workingDirectory: exampleDir);
        if (pubGet.exitCode != 0) {
          markTestSkipped('flutter pub get failed: ${pubGet.stderr}');
          return;
        }
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

      // Ensure example deps are resolved
      if (!File(p.join(exampleDir, '.dart_tool', 'package_config.json'))
          .existsSync()) {
        final pubGet = Process.runSync('flutter', ['pub', 'get'],
            workingDirectory: exampleDir);
        if (pubGet.exitCode != 0) {
          markTestSkipped('flutter pub get failed: ${pubGet.stderr}');
          return;
        }
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
}
