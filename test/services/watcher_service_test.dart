import 'dart:io';

import 'package:analytics_gen/src/services/watcher_service.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  group('WatcherService', () {
    late Directory project;

    setUp(() {
      project = Directory.systemTemp.createTempSync('watcher_service_');
    });

    tearDown(() => project.deleteSync(recursive: true));

    test('generates once, then fails when the events directory is missing',
        () async {
      final logs = <String>[];
      var generations = 0;

      await expectLater(
        WatcherService(projectRoot: project.path, logger: TestLogger(logs))
            .watch(
          eventsPath: 'events',
          onGenerate: () async => generations++,
        ),
        throwsA(
          isA<FileSystemException>()
              .having((e) => e.message, 'message', contains('does not exist')),
        ),
      );

      expect(generations, 1);
      expect(logs, contains('Watching for changes in: events'));
    });
  });
}
