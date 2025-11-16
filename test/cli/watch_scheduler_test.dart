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

    test('marks pending when flush occurs while running', () async {
      // This test ensures the branch inside `_flush` that sets `_pending = true`
      // when a flush triggers while a generation is running is exercised.
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

      // Trigger the first run and wait for it to start.
      scheduler.schedule();
      await Future.delayed(const Duration(milliseconds: 40));
      expect(runs, equals(1));

      // Schedule another run while the first is still active and wait longer
      // than the debounce window so that `_flush` will run while `_isRunning`
      // is still true and set `_pending = true`.
      scheduler.schedule();
      await Future.delayed(const Duration(milliseconds: 80));

      // The second run should not have started yet (still waiting on firstRun)
      expect(runs, equals(1));

      // Completing the first run should trigger the pending run and increment runs
      firstRun.complete();
      await Future.delayed(const Duration(milliseconds: 80));
      expect(runs, equals(2));

      scheduler.dispose();
    });
  });
}
