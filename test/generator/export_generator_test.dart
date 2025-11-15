import 'dart:io';

import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/generator/export_generator.dart';
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

      await firstGenerator.generate();

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

      await secondGenerator.generate();

      expect(csvFile.existsSync(), isTrue);
      expect(jsonFile.existsSync(), isFalse);
    });
  });
}
