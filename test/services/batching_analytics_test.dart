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
        onFlushError: (error, _) => errors.add(error),
      );

      batching.logEvent(name: 'auto');

      await Future<void>.delayed(const Duration(milliseconds: 20));
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
  });
}

final class _FakeAsyncAnalytics implements IAsyncAnalytics {
  final List<_RecordedAsyncEvent> recordedEvents = [];
  bool throwNext = false;
  int? failAtCall;
  int _callCount = 0;

  @override
  Future<void> logEventAsync({
    required String name,
    AnalyticsParams? parameters,
  }) async {
    _callCount++;
    final shouldThrow =
        throwNext || (failAtCall != null && _callCount == failAtCall);
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
