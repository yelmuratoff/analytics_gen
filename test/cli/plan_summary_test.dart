import 'dart:async';
import 'dart:io';

import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/util/logger.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../../bin/src/plan_printer.dart' as plan;

void main() {
  group('generate.dart plan summary', () {
    late Directory tempDir;
    late String eventsPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('analytics_gen_plan_');
      eventsPath = tempDir.path;
      Directory(path.join(eventsPath, 'events')).createSync(recursive: true);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('prints readable plan overview', () async {
      final yamlFile = File(path.join(eventsPath, 'events', 'auth.yaml'));
      await yamlFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: User logged in\n'
        '    parameters:\n'
        '      method: string\n',
      );

      final config = AnalyticsConfig(eventsPath: 'events');

      final lines = <String>[];

      await runZonedGuarded(
        () async {
          await plan.printTrackingPlan(
            eventsPath,
            config,
            logger: const ConsoleLogger(verbose: false),
          );
        },
        (error, stack) => fail('Unexpected error: $error'),
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) {
            lines.add(line);
          },
        ),
      );

      expect(
        lines.any((line) => line.contains('Tracking Plan Overview')),
        isTrue,
      );
      expect(
        lines.any((line) => line.startsWith('Fingerprint: ')),
        isTrue,
      );
      expect(
        lines.any((line) => line.contains('- auth (1 events, 1 parameters)')),
        isTrue,
      );
      expect(
        lines.any((line) => line.contains('auth_login [Active]')),
        isTrue,
      );
      expect(
        lines.any((line) => line.contains('Parameters: method (string)')),
        isTrue,
      );
    });
  });
}
