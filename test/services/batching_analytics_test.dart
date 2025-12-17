import 'dart:async';

import 'package:analytics_gen/analytics_gen.dart';
import 'package:test/test.dart';

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

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(
          delegate.recordedEvents.map((e) => e.name), ['event_a', 'event_b']);
      await batching.flush();
    });

    test('flushInterval periodically drains queue', () async {
      final delegate = _FakeAsyncAnalytics();
      final batching = BatchingAnalytics(
        delegate: delegate,
        maxBatchSize: 10,
        flushInterval: const Duration(milliseconds: 20),
      );

      batching.logEvent(name: 'interval_event');
      expect(delegate.recordedEvents, isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(delegate.recordedEvents.length, 1);

      await batching.dispose();
    });

    test('failed flush requeues the batch', () async {
      final delegate = _FakeAsyncAnalytics()..throwNext = true;
      final batching = BatchingAnalytics(
        delegate: delegate,
        maxBatchSize: 10,
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
        minRetryDelay: const Duration(milliseconds: 1),
        onFlushError: (error, _) => errors.add(error),
      );

      batching.logEvent(name: 'auto');

      await Future<void>.delayed(const Duration(milliseconds: 200));
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
      await Future<void>.delayed(const Duration(milliseconds: 10));

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
      await Future<void>.delayed(const Duration(milliseconds: 10));
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
  });

  test(
      '_startFlush returns immediate Future when nothing pending (via test seam)',
      () async {
    final delegate = _FakeAsyncAnalytics();
    final batching = BatchingAnalytics(delegate: delegate);
    await expectLater(
        batching.startFlushForTest(propagateErrors: true), completes);
  });

  test(
      'startFlush during active flush sets follow-up and returns active future',
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

    // Call startFlushForTest which should detect active flush and set follow up
    final futureDuring = batching.startFlushForTest(propagateErrors: true);

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
    await Future<void>.delayed(const Duration(milliseconds: 10));

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
