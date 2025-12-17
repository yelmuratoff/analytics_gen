@Timeout(Duration(minutes: 2))
library;

import 'dart:io';

import 'package:analytics_gen/src/config/config_loader.dart';
import 'package:analytics_gen/src/config/parser_config.dart';
import 'package:analytics_gen/src/core/exceptions.dart';
import 'package:analytics_gen/src/generator/code_generator.dart';
import 'package:analytics_gen/src/parser/event_loader.dart';
import 'package:analytics_gen/src/parser/yaml_parser.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('Full Pipeline Integration', () {
    late Directory tempDir;
    late String projectRoot;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('analytics_gen_test_');
      projectRoot = tempDir.path;
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (e) {
          print('Warning: Failed to cleanup temp dir: $e');
        }
      }
    });

    test('generates valid Dart code from YAML that compiles and runs',
        () async {
      // 1. Setup: Create YAML configuration and event definitions
      final eventsDir = Directory(path.join(projectRoot, 'events'));
      eventsDir.createSync(recursive: true);

      final configFile = File(path.join(projectRoot, 'analytics_gen.yaml'));
      configFile.writeAsStringSync('''
# analytics_gen.yaml
analytics_gen:
  inputs:
    events: 'events'
  outputs:
    dart: 'analytics'
  naming:
    strategy: snake_case
    template: '{domain}_{event}'
''');

      final authYaml = File(path.join(eventsDir.path, 'auth.yaml'));
      authYaml.writeAsStringSync('''
auth:
  login:
    description: User logged in
    parameters:
      method:
        type: string
        allowed_values: ['email', 'google', 'apple']
      timestamp: int
''');

      // 2. Parse YAML
      final config =
          await loadAnalyticsConfig(projectRoot, 'analytics_gen.yaml');

      final loader = EventLoader(
        eventsPath: path.join(projectRoot, config.inputs.eventsPath),
        fs: const LocalFileSystem(),
      );
      final eventSources = await loader.loadEventFiles();

      final parser = YamlParser(config: ParserConfig(naming: config.naming));
      final domains = await parser.parseEvents(eventSources);

      expect(domains, contains('auth'));
      expect(domains['auth']!.events, hasLength(1));

      // 3. Generate code
      final generator = CodeGenerator(
        config: config,
        projectRoot: projectRoot,
      );
      await generator.generate(domains);

      // 4. Verify generated file exists
      final generatedFile = File(path.join(
          projectRoot, 'lib', 'analytics', 'events', 'auth_events.dart'));
      expect(generatedFile.existsSync(), isTrue,
          reason: 'Generated event file should exist');

      final content = generatedFile.readAsStringSync();
      expect(content, contains('mixin AnalyticsAuth'));
      expect(content, contains('void logAuthLogin'));
      expect(content, contains('enum AnalyticsAuthLoginMethodEnum'));

      // 5. Verify generated code is valid Dart (compile check)
      // We need to create a pubspec.yaml for 'dart analyze' to work properly
      File(path.join(projectRoot, 'pubspec.yaml')).writeAsStringSync('''
name: temp_test_project
environment:
  sdk: ">=3.0.0 <4.0.0"
dependencies:
  meta: ^1.11.0
  analytics_gen:
    path: ${Directory.current.absolute.path}
''');

      // Run pub get to resolve dependencies
      final pubGetResult = await Process.run(
        'dart',
        ['pub', 'get'],
        workingDirectory: projectRoot,
      );
      expect(pubGetResult.exitCode, 0,
          reason: 'dart pub get failed:\n${pubGetResult.stderr}');

      // Analyze the generated files
      final analyzeResult = await Process.run('dart', [
        'analyze',
        path.join(projectRoot, 'lib', 'analytics'),
      ]);

      expect(analyzeResult.exitCode, 0,
          reason:
              'Generated code must analyze without errors:\nSTDOUT:\n${analyzeResult.stdout}\nSTDERR:\n${analyzeResult.stderr}');
    });

    test('fails gracefully when YAML is invalid', () async {
      // Setup invalid YAML
      final eventsDir = Directory(path.join(projectRoot, 'events'));
      eventsDir.createSync(recursive: true);

      // Create valid config
      File(path.join(projectRoot, 'analytics_gen.yaml')).writeAsStringSync('''
analytics_gen:
  inputs:
    events: 'events'
''');

      // Create invalid event definition (invalid key)
      File(path.join(eventsDir.path, 'bad.yaml')).writeAsStringSync('''
auth:
  login:
    description: User logged in
    parameters: "This strictly must be a map"
''');

      final config =
          await loadAnalyticsConfig(projectRoot, 'analytics_gen.yaml');

      final loader = EventLoader(
        eventsPath: path.join(projectRoot, config.inputs.eventsPath),
        fs: const LocalFileSystem(),
      );
      final eventSources = await loader.loadEventFiles();

      final parser = YamlParser(config: ParserConfig(naming: config.naming));

      // Expect parsing to fail
      expect(
        () => parser.parseEvents(eventSources),
        throwsA(isA<AnalyticsAggregateException>()),
      );
    });
  });
}
