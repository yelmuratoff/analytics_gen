import 'dart:io';

import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/config/config_loader.dart';
import 'package:analytics_gen/src/util/logger.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  group('loadAnalyticsConfig', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('config_loader_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    Future<AnalyticsConfig> load(String content) {
      File(p.join(tempDir.path, 'analytics_gen.yaml'))
          .writeAsStringSync(content);
      return loadAnalyticsConfig(
        tempDir.path,
        'analytics_gen.yaml',
        logger: const NoOpLogger(),
      );
    }

    test('uses the defaults for a file with only comments', () async {
      final config = await load('# analytics_gen config\n');

      expect(
        config.inputs.eventsPath,
        AnalyticsConfig.defaultConfig.inputs.eventsPath,
      );
    });

    test('uses the defaults and shows a starter config without a file',
        () async {
      final logs = <String>[];

      final config = await loadAnalyticsConfig(
        tempDir.path,
        'analytics_gen.yaml',
        logger: TestLogger(logs),
      );

      expect(
        config.inputs.eventsPath,
        AnalyticsConfig.defaultConfig.inputs.eventsPath,
      );
      expect(
        logs.first,
        'No config file found at analytics_gen.yaml, using defaults',
      );
      expect(logs, contains('analytics_gen:'));
    });

    test('names the file when its root is not a map', () async {
      await expectLater(
        load('- events\n'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            'Invalid configuration file "analytics_gen.yaml": '
                'expected a map but got a list',
          ),
        ),
      );
    });
  });
}
