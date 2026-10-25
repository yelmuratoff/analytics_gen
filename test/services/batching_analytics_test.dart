import 'dart:async';

import 'package:analytics_gen/analytics_gen.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  group('BatchingAnalytics', () {
    test('flush sends buffered events to delegate', () async {
      final delegate = _FakeAsyncAnalytics();
      final batching = BatchingAnalytics(
        delegate: delegate,
        maxBatchSize: 5,
      );

      batching.logEvent(name: 'event_a');
      batching.logEvent(name: 'event_b', parameters: {'k': 'v'});

      expect(delegate.recordedEvents, isEmpty);

      await batching.flush();

      expect(delegate.recordedEvents.length, 2);
      expect(delegate.recordedEvents.first.name, 'event_a');
      expect(
        delegate.recordedEvents.last.parameters,
        equals({'k': 'v'}),
      );
    });

    test('auto flush triggers when maxBatchSize reached', () async {
      final delegate = _FakeAsyncAnalytics();
      final batching = BatchingAnalytics(
        delegate: delegate,
        maxBatchSize: 2,
      );

      batching.logEvent(name: 'event_a');
      batching.logEvent(name: 'event_b');

      await pumpEventQueue();

      expect(
          delegate.recordedEvents.map((e) => e.name), ['event_a', 'event_b']);
      await batching.flush();
    });

    test('flushInterval periodically drains queue', () {
      fakeAsync((async) {
        final delegate = _FakeAsyncAnalytics();
        final batching = BatchingAnalytics(
          delegate: delegate,
          maxBatchSize: 10,
          flushInterval: const Duration(milliseconds: 20),
        );

        batching.logEvent(name: 'interval_event');
        async.elapse(const Duration(milliseconds: 19));
        expect(delegate.recordedEvents, isEmpty);

        async.elapse(const Duration(milliseconds: 1));
        expect(delegate.recordedEvents.length, 1);

        batching.dispose();
        async.flushMicrotasks();
      });
    });

    test('waits for the backoff before a failed flush completes', () {
      fakeAsync((async) {
        final batching = BatchingAnalytics(
          delegate: _FakeAsyncAnalytics()..alwaysThrow = true,
          maxRetries: 5,
          minRetryDelay: const Duration(milliseconds: 100),
          maxRetryDelay: const Duration(milliseconds: 150),
          onFlushError: (_, __) {},
        );
        batching.logEvent(name: 'unstable');

        var completed = 0;
        void flush() {
          batching.flush().catchError((_) {}).whenComplete(() => completed++);
        }

        flush();
        async.elapse(const Duration(milliseconds: 99));
        expect(completed, 0);
        async.elapse(const Duration(milliseconds: 1));
        expect(completed, 1, reason: 'first retry waits minRetryDelay');

        flush();
        async.elapse(const Duration(milliseconds: 149));
        expect(completed, 1);
        async.elapse(const Duration(milliseconds: 1));
        expect(completed, 2, reason: 'doubled delay is capped');
      });
    });

    test('failed flush requeues the batch', () async {
      final delegate = _FakeAsyncAnalytics()..throwNext = true;
      final batching = BatchingAnalytics(
        delegate: delegate,
        maxBatchSize: 10,
        minRetryDelay: Duration.zero,
        onFlushError: (_, __) {},
      );

      batching.logEvent(name: 'unstable');

      await expectLater(
        () async => await batching.flush(),
        throwsA(isA<StateError>()),
      );
      expect(delegate.recordedEvents, isEmpty);

      delegate.throwNext = false;
      await batching.flush();

      expect(delegate.recordedEvents.length, 1);
      expect(delegate.recordedEvents.first.name, 'unstable');
    });

    test('auto flush failures trigger onFlushError hook', () async {
      final delegate = _FakeAsyncAnalytics()..throwNext = true;
      final errors = <Object>[];
      final batching = BatchingAnalytics(
        delegate: delegate,
        maxBatchSize: 1,
        minRetryDelay: Duration.zero,
        onFlushError: (error, _) => errors.add(error),
      );

      batching.logEvent(name: 'auto');

      await pumpEventQueue();
      expect(errors, isNotEmpty);
      expect(delegate.recordedEvents, isEmpty);

      delegate.throwNext = false;
      await batching.flush();

      expect(delegate.recordedEvents.length, 1);
      await batching.dispose();
    });

    test('flush keeps successfully delivered events on failure', () async {
      final delegate = _FakeAsyncAnalytics()..failAtCall = 2;
      final batching = BatchingAnalytics(
        delegate: delegate,
        maxBatchSize: 10,
        minRetryDelay: Duration.zero,
        onFlushError: (_, __) {},
      );

      batching.logEvent(name: 'first');
      batching.logEvent(name: 'second');
      batching.logEvent(name: 'third');

      await expectLater(
        () async => batching.flush(),
        throwsA(isA<StateError>()),
      );

      expect(
        delegate.recordedEvents.map((e) => e.name),
        ['first'],
        reason: 'first event should succeed before failure',
      );

      await batching.flush();

      expect(
        delegate.recordedEvents.map((e) => e.name),
        ['first', 'second', 'third'],
        reason: 'only remaining events should be retried',
      );

      await batching.dispose();
    });

    test('poison pill event is dropped after maxRetries', () async {
      final delegate = _FakeAsyncAnalytics()..alwaysThrow = true;
      final batching = BatchingAnalytics(
        delegate: delegate,
        maxBatchSize: 1,
        maxRetries: 2,
        minRetryDelay: Duration.zero,
        onFlushError: (_, __) {},
      );

      batching.logEvent(name: 'poison');

      // First attempt (retryCount -> 1)
      await expectLater(
        () async => await batching.flush(),
        throwsA(isA<StateError>()),
      );

      // Second attempt (retryCount -> 2, dropped)
      await expectLater(
        () async => await batching.flush(),
        throwsA(isA<StateError>()),
      );

      // Third attempt - queue should be empty
      await batching.flush();
      expect(delegate.recordedEvents, isEmpty);
    });

    test('onEventDropped is called when event is dropped', () async {
      final delegate = _FakeAsyncAnalytics()..alwaysThrow = true;
      final droppedEvents = <String>[];
      final batching = BatchingAnalytics(
        delegate: delegate,
        maxBatchSize: 1,
        maxRetries: 2,
        minRetryDelay: Duration.zero,
        onEventDropped: (name, params, error, stack) {
          droppedEvents.add(name);
        },
        onFlushError: (_, __) {},
      );

      batching.logEvent(name: 'poison');

      // First attempt (retryCount -> 1)
      await expectLater(
        () async => await batching.flush(),
        throwsA(isA<StateError>()),
      );

      // Second attempt (retryCount -> 2, dropped)
      await expectLater(
        () async => await batching.flush(),
        throwsA(isA<StateError>()),
      );

      expect(droppedEvents, ['poison']);
    });

    test('schedules follow-up flush when logEvent during active flush',
        () async {
      final c1 = Completer<void>();
      final c2 = Completer<void>();
      final delegate = _DelayingAsyncAnalytics([c1, c2]);
      final batching = BatchingAnalytics(delegate: delegate);

      // Start first flush
      batching.logEvent(name: 'e1');
      final flushFuture = batching.flush();

      // While the flush is active (blocked on c1), add another event
      batching.logEvent(name: 'e2');

      // e1 should not be recorded yet; e2 neither
      expect(delegate.recordedEvents, isEmpty);

      // Allow first event to complete; this should trigger a follow-up flush
      c1.complete();
      await pumpEventQueue();

      // e1 should have been recorded, e2 still pending
      expect(delegate.recordedEvents.map((e) => e.name), ['e1']);

      // Allow second event to complete
      c2.complete();
      await flushFuture;

      expect(delegate.recordedEvents.map((e) => e.name), ['e1', 'e2']);
    });

    test('dispose waits for active flush to complete', () async {
      final c1 = Completer<void>();
      final delegate = _DelayingAsyncAnalytics([c1]);
      final batching = BatchingAnalytics(delegate: delegate);

      batching.logEvent(name: 'e1');
      final flushFuture = batching.flush();

      var done = false;
      final disposing = batching.dispose().then((_) => done = true);

      // dispose shouldn't complete while flush is blocked
      await pumpEventQueue();
      expect(done, isFalse);

      // allow flush to complete
      c1.complete();
      await flushFuture;
      await disposing;
      expect(done, isTrue);
    });

    test('_startFlush returns immediate Future when nothing pending', () async {
      final delegate = _FakeAsyncAnalytics();
      final batching = BatchingAnalytics(delegate: delegate);
      await expectLater(batching.flush(), completes);
    });

    test('dispose delivers events re-queued by a failed automatic flush',
        () async {
      final delegate = _FakeAsyncAnalytics()..throwNext = true;
      final batching = BatchingAnalytics(
        delegate: delegate,
        maxBatchSize: 1,
        minRetryDelay: Duration.zero,
        onFlushError: (_, __) {},
      );

      batching.logEvent(name: 'first');
      await batching.dispose();

      expect(delegate.recordedEvents.map((e) => e.name), ['first']);
    });

    test('drops an event logged after dispose and reports it', () async {
      final delegate = _FakeAsyncAnalytics();
      final dropped = <(String, Object)>[];
      final batching = BatchingAnalytics(
        delegate: delegate,
        maxBatchSize: 1,
        onEventDropped: (name, _, error, __) => dropped.add((name, error)),
      );
      await batching.dispose();

      batching.logEvent(name: 'late');
      await batching.flush();

      expect(delegate.recordedEvents, isEmpty);
      expect(dropped.single.$1, 'late');
      expect(dropped.single.$2, isA<StateError>());
    });

    test('logs a dropped event when no onEventDropped handler is set',
        () async {
      final logs = <String>[];
      final batching = BatchingAnalytics(
        delegate: _FakeAsyncAnalytics(),
        logger: TestLogger(logs),
      );
      await batching.dispose();

      batching.logEvent(name: 'late');

      expect(logs, [
        '[BatchingAnalytics] Dropped event "late": Bad state: '
            'logEvent was called after dispose.',
      ]);
    });

    test('logs a failed flush and rethrows the delegate error', () async {
      final logs = <String>[];
      final batching = BatchingAnalytics(
        delegate: _FakeAsyncAnalytics()..throwNext = true,
        minRetryDelay: Duration.zero,
        logger: TestLogger(logs),
      );

      batching.logEvent(name: 'unstable');

      await expectLater(batching.flush(), throwsA(isA<StateError>()));
      expect(logs, [
        '[BatchingAnalytics] Flush failed',
        'Bad state: delegate failure',
      ]);
    });

    test('drops the oldest events beyond maxQueueSize', () async {
      final delegate = _FakeAsyncAnalytics();
      final dropped = <String>[];
      final batching = BatchingAnalytics(
        delegate: delegate,
        maxQueueSize: 2,
        onEventDropped: (name, _, __, ___) => dropped.add(name),
      );

      batching.logEvent(name: 'a');
      batching.logEvent(name: 'b');
      batching.logEvent(name: 'c');
      await batching.flush();

      expect(dropped, ['a']);
      expect(delegate.recordedEvents.map((e) => e.name), ['b', 'c']);
    });
  });

  test('flush during an active flush delivers events logged meanwhile',
      () async {
    final c1 = Completer<void>();
    final c2 = Completer<void>();
    final delegate = _DelayingAsyncAnalytics([c1, c2]);
    final batching = BatchingAnalytics(delegate: delegate);

    // Start first flush
    batching.logEvent(name: 'e1');
    final f1 = batching.flush();

    // Add pending e2
    batching.logEvent(name: 'e2');

    final futureDuring = batching.flush();

    // complete first; this will allow f1 to finish
    c1.complete();
    await f1;

    // follow-up should happen and record e2; allow c2 to finish
    c2.complete();
    await futureDuring;

    expect(delegate.recordedEvents.map((e) => e.name), ['e1', 'e2']);
  });

  test('scheduleAutoFlush sets followUp when activeFlush present', () async {
    final c1 = Completer<void>();
    final c2 = Completer<void>();
    final delegate = _DelayingAsyncAnalytics([c1, c2]);
    final batching = BatchingAnalytics(delegate: delegate, maxBatchSize: 1);

    // Start first flush
    batching.logEvent(name: 'e1');
    final f1 = batching.flush();

    // Add pending event to trigger scheduleAutoFlush (maxBatchSize=1)
    batching.logEvent(name: 'e2');

    // Allow first flush to finish; this should schedule follow-up
    c1.complete();
    await f1;

    // Allow second to finish
    c2.complete();
    // Wait a short while for the follow-up to finish
    await pumpEventQueue();

    expect(delegate.recordedEvents.map((e) => e.name), ['e1', 'e2']);
  });
}

final class _FakeAsyncAnalytics implements IAsyncAnalytics {
  final List<_RecordedAsyncEvent> recordedEvents = [];
  bool throwNext = false;
  bool alwaysThrow = false;
  int? failAtCall;
  int _callCount = 0;

  @override
  Future<void> logEventAsync({
    required String name,
    AnalyticsParams? parameters,
  }) async {
    _callCount++;
    final shouldThrow = alwaysThrow ||
        throwNext ||
        (failAtCall != null && _callCount == failAtCall);
    if (shouldThrow) {
      throwNext = false;
      if (failAtCall == _callCount) {
        failAtCall = null;
      }
      throw StateError('delegate failure');
    }

    recordedEvents.add(_RecordedAsyncEvent(name, parameters));
  }
}

final class _RecordedAsyncEvent {
  _RecordedAsyncEvent(this.name, this.parameters);

  final String name;
  final AnalyticsParams? parameters;
}

final class _DelayingAsyncAnalytics implements IAsyncAnalytics {
  _DelayingAsyncAnalytics(this.completers);

  final List<Completer<void>> completers;

  final List<_RecordedAsyncEvent> recordedEvents = [];
  int _callCount = 0;

  @override
  Future<void> logEventAsync(
      {required String name, AnalyticsParams? parameters}) async {
    final idx = _callCount++;
    if (idx < completers.length) {
      await completers[idx].future;
    }
    recordedEvents.add(_RecordedAsyncEvent(name, parameters));
    // No optional throws in this helper
  }
}
