import 'dart:async';
import 'package:meta/meta.dart';

import '../core/analytics_interface.dart';
import '../core/async_analytics_interface.dart';
import '../util/logger.dart';

/// Signature for error handler invoked when batch flush fails.
typedef BatchFlushErrorHandler = void Function(
  Object error,
  StackTrace stackTrace,
);

/// Signature for handler invoked when an event is dropped after max retries.
typedef EventDroppedHandler = void Function(
  String name,
  AnalyticsParams? parameters,
  Object error,
  StackTrace stackTrace,
);

/// Buffers analytics events and flushes them in batches to an async delegate.
///
/// Use this wrapper when you need to control network usage (cellular metering,
/// flaky providers, cold starts) without changing the synchronous
/// `IAnalytics.logEvent` contract exposed to the rest of the app.
final class BatchingAnalytics implements IAnalytics {
  /// Creates a new batching analytics service.
  ///
  /// Failures without a matching [onFlushError] or [onEventDropped] handler
  /// are written to [logger], which defaults to a [ConsoleLogger].
  BatchingAnalytics({
    required IAsyncAnalytics delegate,
    this.maxBatchSize = 20,
    this.maxRetries = 3,
    this.minRetryDelay = const Duration(milliseconds: 500),
    this.maxRetryDelay = const Duration(seconds: 10),
    this.maxQueueSize,
    Duration? flushInterval,
    this.onFlushError,
    this.onEventDropped,
    Logger? logger,
  })  : assert(maxBatchSize > 0, 'maxBatchSize must be greater than zero.'),
        assert(maxRetries >= 0, 'maxRetries must be non-negative.'),
        assert(
          maxQueueSize == null || maxQueueSize > 0,
          'maxQueueSize must be greater than zero.',
        ),
        _delegate = delegate,
        _logger = logger ?? const ConsoleLogger() {
    if (flushInterval != null) {
      _timer = Timer.periodic(flushInterval, (_) {
        if (_pending.isNotEmpty) {
          _scheduleAutoFlush();
        }
      });
    }
  }

  final IAsyncAnalytics _delegate;
  final Logger _logger;

  /// The maximum number of events to buffer before flushing.
  final int maxBatchSize;

  /// How many times an event may fail to deliver before it is dropped.
  ///
  /// A failed event stays at the front of the queue for the next flush. Once
  /// it has failed [maxRetries] times it is dropped and reported to
  /// [onEventDropped]. A value of 0 drops an event on its first failure, the
  /// same as 1.
  final int maxRetries;

  /// The minimum delay between retries.
  final Duration minRetryDelay;

  /// The maximum delay between retries.
  final Duration maxRetryDelay;

  /// The most events kept waiting for delivery, or null for no limit.
  ///
  /// When a new event would exceed the limit, the oldest waiting events are
  /// dropped and reported to [onEventDropped]. Set a limit when the delegate
  /// can stay unreachable for long, so the queue cannot grow without bound.
  final int? maxQueueSize;

  /// Called with the error of every failed flush.
  ///
  /// A manual [flush] reports its failure here and also throws it. When null,
  /// the failure is logged instead.
  final BatchFlushErrorHandler? onFlushError;

  /// Called for every event that is dropped instead of delivered (a dead
  /// letter queue).
  ///
  /// An event is dropped after failing [maxRetries] times, when it exceeds
  /// [maxQueueSize], or when it is logged after [dispose]. When null, the
  /// drop is logged instead.
  final EventDroppedHandler? onEventDropped;

  final List<_QueuedAnalyticsEvent> _pending = <_QueuedAnalyticsEvent>[];
  Future<void>? _activeFlush;
  Timer? _timer;
  bool _needsFollowUpFlush = false;
  bool _disposed = false;

  @override
  void logEvent({required String name, AnalyticsParams? parameters}) {
    final event = _QueuedAnalyticsEvent(name, parameters);
    if (_disposed) {
      _dropEvent(
        event,
        StateError('logEvent was called after dispose.'),
        StackTrace.current,
      );
      return;
    }
    _pending.add(event);
    _enforceQueueLimit();
    if (_activeFlush != null) {
      _needsFollowUpFlush = true;
    }
    if (_pending.length >= maxBatchSize) {
      _scheduleAutoFlush();
    }
  }

  /// Flushes buffered events and waits for completion.
  ///
  /// Throws the delegate's error when an event fails to deliver. The failed
  /// event and every event after it stay queued for the next flush, and the
  /// failure is also reported to [onFlushError]. This lets callers handle
  /// failures when flushing manually, for example when the app goes to the
  /// background.
  ///
  /// Automatic flushes, triggered by [maxBatchSize] or `flushInterval`,
  /// report failures to [onFlushError] without throwing.
  ///
  /// If a flush is already in progress, this returns the future of the
  /// active flush.
  Future<void> flush() {
    if (_pending.isEmpty && _activeFlush == null) {
      return Future<void>.value();
    }
    return _startFlush(propagateErrors: true);
  }

  /// Cancels timers and delivers the events that are still queued.
  ///
  /// Waits for an automatic flush in progress, whose failure was already
  /// reported to [onFlushError], then flushes what remains. Throws if that
  /// final flush fails. Events logged after [dispose] are dropped.
  Future<void> dispose() async {
    _disposed = true;
    _timer?.cancel();
    await _activeFlush?.catchError((Object _) {});
    await flush();
    _needsFollowUpFlush = false;
  }

  void _enforceQueueLimit() {
    final limit = maxQueueSize;
    if (limit == null) return;
    while (_pending.length > limit) {
      _dropEvent(
        _pending.removeAt(0),
        StateError('The queue exceeded maxQueueSize ($limit).'),
        StackTrace.current,
      );
    }
  }

  void _dropEvent(
    _QueuedAnalyticsEvent event,
    Object error,
    StackTrace stackTrace,
  ) {
    final handler = onEventDropped;
    if (handler == null) {
      _logger.warning(
        '[BatchingAnalytics] Dropped event "${event.name}": $error',
      );
      return;
    }
    handler(event.name, event.parameters, error, stackTrace);
  }

  void _scheduleAutoFlush() {
    if (_pending.isEmpty) {
      return;
    }
    if (_activeFlush != null) {
      _needsFollowUpFlush = true;
      return;
    }
    _startFlush(propagateErrors: false);
  }

  Future<void> _startFlush({required bool propagateErrors}) {
    if (_pending.isEmpty && _activeFlush == null) {
      return Future<void>.value();
    }

    if (_activeFlush != null) {
      if (_pending.isNotEmpty) {
        _needsFollowUpFlush = true;
      }
      return propagateErrors ? _activeFlush! : _activeFlush!.catchError((_) {});
    }

    final completer = Completer<void>();
    final future = completer.future;
    _activeFlush = future;

    () async {
      var didFail = false;
      try {
        await _drainPending();
        if (!completer.isCompleted) {
          completer.complete();
        }
      } catch (error, stackTrace) {
        didFail = true;
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      } finally {
        if (identical(_activeFlush, future)) {
          _activeFlush = null;
        }
        if (didFail) {
          // A failed flush re-queues remaining events. Do not auto-retry here:
          // - Manual `flush()` callers expect to handle the error and decide when to retry.
          // - Auto flush errors are surfaced via `onFlushError` and should not loop silently.
          _needsFollowUpFlush = false;
        }

        if (_pending.isNotEmpty && _needsFollowUpFlush) {
          _needsFollowUpFlush = false;
          _scheduleAutoFlush();
        } else if (_pending.isEmpty) {
          _needsFollowUpFlush = false;
        }
      }
    }();

    // If we are just auto-flushing, we don't want to crash the caller (e.g. dispose)
    // or leave an unhandled future error.
    if (!propagateErrors) {
      // ignore: unawaited_futures
      future.catchError((_) {});
    }

    return future;
  }

  /// Exposes [_startFlush] for testing only.
  @Deprecated(
    'Use flush(), which starts the same flush with propagateErrors: true. '
    'This test hook will be removed in the next major release.',
  )
  @visibleForTesting
  Future<void> startFlushForTest({required bool propagateErrors}) =>
      _startFlush(propagateErrors: propagateErrors);

  Future<void> _drainPending() async {
    if (_pending.isEmpty) {
      return;
    }

    final batch = List<_QueuedAnalyticsEvent>.from(_pending);
    _pending.clear();

    var nextIndex = 0;
    try {
      for (; nextIndex < batch.length; nextIndex++) {
        final event = batch[nextIndex];
        await _delegate.logEventAsync(
          name: event.name,
          parameters: event.parameters,
        );
      }
    } catch (error, stackTrace) {
      if (nextIndex < batch.length) {
        final failedEvent = batch[nextIndex].withIncrementedRetry();

        if (failedEvent.retryCount >= maxRetries) {
          // Drop the poison pill event by skipping it in the re-queue
          _dropEvent(failedEvent, error, stackTrace);
          nextIndex++;
        } else {
          // Backoff before retrying
          final delay = _calculateBackoff(failedEvent.retryCount);
          await Future.delayed(delay);
          // Replace the failed event with updated retry count
          batch[nextIndex] = failedEvent;
        }

        if (nextIndex < batch.length) {
          final remaining = batch.getRange(nextIndex, batch.length);
          _pending.insertAll(0, remaining);
        }
      }
      _reportFlushError(error, stackTrace);
      rethrow;
    }
  }

  void _reportFlushError(Object error, StackTrace stackTrace) {
    final handler = onFlushError;
    if (handler == null) {
      _logger.error('[BatchingAnalytics] Flush failed', error, stackTrace);
      return;
    }
    handler(error, stackTrace);
  }

  Duration _calculateBackoff(int retryCount) {
    final delay = minRetryDelay * (1 << (retryCount - 1));
    return delay > maxRetryDelay ? maxRetryDelay : delay;
  }
}

/// Immutable queued event with retry tracking.
final class _QueuedAnalyticsEvent {
  const _QueuedAnalyticsEvent(
    this.name,
    this.parameters, {
    this.retryCount = 0,
  });

  final String name;
  final AnalyticsParams? parameters;
  final int retryCount;

  /// Returns a new instance with incremented retry count.
  _QueuedAnalyticsEvent withIncrementedRetry() => _QueuedAnalyticsEvent(
        name,
        parameters,
        retryCount: retryCount + 1,
      );
}
