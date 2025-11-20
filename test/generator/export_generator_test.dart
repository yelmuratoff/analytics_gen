import 'dart:io';

import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/generator/export_generator.dart';
import 'package:analytics_gen/src/parser/event_loader.dart';
import 'package:analytics_gen/src/parser/yaml_parser.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('ExportGenerator', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('analytics_gen_exports_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('cleans the output directory before generating new exports', () async {
      final eventsDir = Directory(path.join(tempDir.path, 'events'));
      eventsDir.createSync(recursive: true);

      final yamlFile = File(path.join(eventsDir.path, 'auth.yaml'));
      await yamlFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: User logs in\n'
        '    parameters: {}\n',
      );

      final firstConfig = AnalyticsConfig(
        eventsPath: 'events',
        exportsPath: 'generated',
        generateCsv: true,
        generateJson: true,
      );
      final firstGenerator = ExportGenerator(
        config: firstConfig,
        projectRoot: tempDir.path,
      );

      final loader = EventLoader(
        eventsPath: path.join(tempDir.path, firstConfig.eventsPath),
      );
      final sources = await loader.loadEventFiles();
      final parser = YamlParser();
      final domains = await parser.parseEvents(sources);

      await firstGenerator.generate(domains);

      final outputDir = Directory(path.join(tempDir.path, 'generated'));
      final csvFile = File(path.join(outputDir.path, 'analytics_events.csv'));
      final jsonFile = File(path.join(outputDir.path, 'analytics_events.json'));

      expect(csvFile.existsSync(), isTrue);
      expect(jsonFile.existsSync(), isTrue);

      final secondConfig = AnalyticsConfig(
        eventsPath: 'events',
        exportsPath: 'generated',
        generateCsv: true,
        generateJson: false,
      );
      final secondGenerator = ExportGenerator(
        config: secondConfig,
        projectRoot: tempDir.path,
      );

      await secondGenerator.generate(domains);

      expect(csvFile.existsSync(), isTrue);
      expect(jsonFile.existsSync(), isFalse);
    });

    test('skips export generation when no analytics events exist', () async {
      final eventsDir = Directory(path.join(tempDir.path, 'events'));
      eventsDir.createSync(recursive: true);

      final logs = <String>[];
      final config = AnalyticsConfig(
        eventsPath: 'events',
        generateCsv: true,
      );
      final generator = ExportGenerator(
        config: config,
        projectRoot: tempDir.path,
        log: logs.add,
      );

      final loader = EventLoader(
        eventsPath: path.join(tempDir.path, config.eventsPath),
      );
      final sources = await loader.loadEventFiles();
      final parser = YamlParser();
      final domains = await parser.parseEvents(sources);

      await generator.generate(domains);

      final defaultAssets =
          Directory(path.join(tempDir.path, 'assets', 'generated'));
      expect(defaultAssets.existsSync(), isFalse);
      expect(
        logs,
        contains('No analytics events found. Skipping export generation.'),
      );
    });

    test('writes CSV/JSON/SQL to default assets path and logs each step',
        () async {
      final eventsDir = Directory(path.join(tempDir.path, 'events'));
      eventsDir.createSync(recursive: true);

      final yamlFile = File(path.join(eventsDir.path, 'billing.yaml'));
      await yamlFile.writeAsString(
        'billing:\n'
        '  purchase:\n'
        '    description: Records purchase\n'
        '    parameters: {}\n',
      );

      final logs = <String>[];
      final config = AnalyticsConfig(
        eventsPath: 'events',
        generateCsv: true,
        generateJson: true,
        generateSql: true,
      );
      final generator = ExportGenerator(
        config: config,
        projectRoot: tempDir.path,
        log: logs.add,
      );

      final loader = EventLoader(
        eventsPath: path.join(tempDir.path, config.eventsPath),
      );
      final sources = await loader.loadEventFiles();
      final parser = YamlParser();
      final domains = await parser.parseEvents(sources);

      await generator.generate(domains);

      final outputDir = path.join(tempDir.path, 'assets', 'generated');
      final csvFile = File(path.join(outputDir, 'analytics_events.csv'));
      final jsonFile = File(path.join(outputDir, 'analytics_events.json'));
      final sqlFile = File(path.join(outputDir, 'create_database.sql'));

      expect(csvFile.existsSync(), isTrue);
      expect(jsonFile.existsSync(), isTrue);
      expect(sqlFile.existsSync(), isTrue);

      expect(
        logs,
        contains(
          '✓ Generated CSV at: ${path.join(outputDir, 'analytics_events.csv')}',
        ),
      );
      expect(
        logs,
        contains(
          '✓ Generated JSON at: ${path.join(outputDir, 'analytics_events.json')}',
        ),
      );
      expect(
        logs,
        contains(
          '✓ Generated SQL at: ${path.join(outputDir, 'create_database.sql')}',
        ),
      );
    });
  });
}
