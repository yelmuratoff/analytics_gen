import 'dart:io';

import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/generator/code_generator.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('CodeGenerator', () {
    late Directory tempProject;

    setUp(() {
      tempProject = Directory.systemTemp.createTempSync('analytics_gen_code_');
      // Create minimal project structure
      Directory(p.join(tempProject.path, 'lib')).createSync(recursive: true);
      Directory(p.join(tempProject.path, 'events')).createSync(recursive: true);
    });

    tearDown(() {
      if (tempProject.existsSync()) {
        tempProject.deleteSync(recursive: true);
      }
    });

    test('generates domain mixin and Analytics singleton', () async {
      final eventsFile = File(p.join(tempProject.path, 'events', 'auth.yaml'));
      await eventsFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: User logs in\n'
        '    parameters:\n'
        '      method: string\n',
      );

      final config = AnalyticsConfig(
        eventsPath: 'events',
        outputPath: 'src/analytics/generated',
      );

      final logs = <String>[];
      final generator = CodeGenerator(
        config: config,
        projectRoot: tempProject.path,
        log: logs.add,
      );

      await generator.generate();

      final outputDir =
          Directory(p.join(tempProject.path, 'lib', config.outputPath));
      final eventsDir = Directory(p.join(outputDir.path, 'events'));
      final analyticsFile = File(p.join(outputDir.path, 'analytics.dart'));
      final authFile = File(p.join(eventsDir.path, 'auth_events.dart'));

      expect(eventsDir.existsSync(), isTrue);
      expect(analyticsFile.existsSync(), isTrue);
      expect(authFile.existsSync(), isTrue);

      final authContent = await authFile.readAsString();
      expect(authContent, contains('mixin AnalyticsAuth on AnalyticsBase'));
      expect(
        authContent,
        contains('void logAuthLogin({'),
      );
      expect(
        authContent,
        contains('logger.logEvent('),
      );

      final analyticsContent = await analyticsFile.readAsString();
      expect(analyticsContent, contains('final class Analytics extends'));
      expect(analyticsContent, contains('Analytics.initialize'));

      // Ensure logging used the injectable logger
      expect(
        logs.where((m) => m.contains('Starting analytics code generation')),
        isNotEmpty,
      );
    });
  });
}

