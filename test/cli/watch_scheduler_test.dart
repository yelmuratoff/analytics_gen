import 'dart:async';

import 'package:analytics_gen/src/cli/watch_scheduler.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

void main() {
  group('WatchRegenerationScheduler', () {
    const debounce = Duration(milliseconds: 20);

    test('restarts the debounce window on every schedule call', () {
      fakeAsync((async) {
        var runs = 0;
        final scheduler = WatchRegenerationScheduler(
          debounceDuration: debounce,
          onGenerate: () async => runs++,
        );

        scheduler.schedule();
        async.elapse(const Duration(milliseconds: 10));
        scheduler.schedule();
        async.elapse(const Duration(milliseconds: 19));
        expect(runs, 0);

        async.elapse(const Duration(milliseconds: 1));
        expect(runs, 1);

        scheduler.dispose();
      });
    });

    test('queues another generation while one is running', () {
      fakeAsync((async) {
        final firstRun = Completer<void>();
        var runs = 0;
        final scheduler = WatchRegenerationScheduler(
          debounceDuration: debounce,
          onGenerate: () async {
            runs++;
            if (runs == 1) await firstRun.future;
          },
        );

        scheduler.schedule();
        async.elapse(debounce);
        expect(runs, 1);

        scheduler.schedule();
        async.elapse(const Duration(milliseconds: 10));
        firstRun.complete();
        async.elapse(debounce);

        expect(runs, 2);
        scheduler.dispose();
      });
    });

    test('runs a flush that fired during a generation once it finishes', () {
      fakeAsync((async) {
        final firstRun = Completer<void>();
        var runs = 0;
        final scheduler = WatchRegenerationScheduler(
          debounceDuration: debounce,
          onGenerate: () async {
            runs++;
            if (runs == 1) await firstRun.future;
          },
        );

        scheduler.schedule();
        async.elapse(debounce);
        scheduler.schedule();
        async.elapse(debounce * 4);
        expect(runs, 1);

        firstRun.complete();
        async.elapse(debounce);

        expect(runs, 2);
        scheduler.dispose();
      });
    });
  });
}
