import 'dart:async';

import 'package:analytics_gen/src/cli/watch_scheduler.dart';
import 'package:test/test.dart';

void main() {
  group('WatchRegenerationScheduler', () {
    test('debounces rapid schedule calls', () async {
      var runs = 0;
      final scheduler = WatchRegenerationScheduler(
        debounceDuration: const Duration(milliseconds: 20),
        onGenerate: () async {
          runs++;
        },
      );

      scheduler.schedule();
      scheduler.schedule();

      await Future.delayed(const Duration(milliseconds: 80));

      expect(runs, equals(1));

      scheduler.dispose();
    });

    test('queues another generation while one is running', () async {
      final firstRun = Completer<void>();
      var runs = 0;
      final scheduler = WatchRegenerationScheduler(
        debounceDuration: const Duration(milliseconds: 20),
        onGenerate: () async {
          runs++;
          if (runs == 1) {
            await firstRun.future;
          }
        },
      );

      scheduler.schedule();
      await Future.delayed(const Duration(milliseconds: 40));
      expect(runs, equals(1));

      scheduler.schedule();
      await Future.delayed(const Duration(milliseconds: 10));

      firstRun.complete();
      await Future.delayed(const Duration(milliseconds: 80));
      expect(runs, equals(2));

      scheduler.dispose();
    });
  });
}
