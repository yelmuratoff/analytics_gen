import 'dart:async';
import 'package:meta/meta.dart';

import '../core/analytics_interface.dart';
import '../core/async_analytics_interface.dart';

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
  BatchingAnalytics({
    required IAsyncAnalytics delegate,
    this.maxBatchSize = 20,
    this.maxRetries = 3,
    this.minRetryDelay = const Duration(milliseconds: 500),
    this.maxRetryDelay = const Duration(seconds: 10),
    Duration? flushInterval,
    this.onFlushError,
    this.onEventDropped,
  })  : assert(maxBatchSize > 0, 'maxBatchSize must be greater than zero.'),
        assert(maxRetries >= 0, 'maxRetries must be non-negative.'),
        _delegate = delegate {
    if (flushInterval != null) {
      _timer = Timer.periodic(flushInterval, (_) {
        if (_pending.isNotEmpty) {
          _scheduleAutoFlush();
        }
      });
    }
  }

  final IAsyncAnalytics _delegate;

  /// The maximum number of events to buffer before flushing.
  final int maxBatchSize;

  /// The maximum number of times to retry a failed batch.
  final int maxRetries;

  /// The minimum delay between retries.
  final Duration minRetryDelay;

  /// The maximum delay between retries.
  final Duration maxRetryDelay;

  /// Callback for handling flush errors.
  final BatchFlushErrorHandler? onFlushError;

  /// Callback for handling dropped events (Dead Letter Queue).
  final EventDroppedHandler? onEventDropped;

  final List<_QueuedAnalyticsEvent> _pending = <_QueuedAnalyticsEvent>[];
  Future<void>? _activeFlush;
  Timer? _timer;
  bool _needsFollowUpFlush = false;

  @override
  void logEvent({required String name, AnalyticsParams? parameters}) {
    _pending.add(_QueuedAnalyticsEvent(name, parameters));
    if (_activeFlush != null) {
      _needsFollowUpFlush = true;
    }
    if (_pending.length >= maxBatchSize) {
      _scheduleAutoFlush();
    }
  }

  /// Flushes buffered events and waits for completion.
  ///
  /// If the flush fails (e.g. network error) and retries are exhausted,
  /// this method will throw the underlying exception. This allows callers
  /// to handle failures when manually flushing (e.g. on app background).
  ///
  /// In contrast, automatic background flushes (triggered by [maxBatchSize]
  /// or `flushInterval`) catch errors and report them to [onFlushError]
  /// without throwing.
  ///
  /// If a flush is already in progress, this returns the future of the
  /// active flush.
  Future<void> flush() {
    if (_pending.isEmpty && _activeFlush == null) {
      return Future<void>.value();
    }
    return _startFlush(propagateErrors: true);
  }

  /// Cancels timers and drains pending events.
  Future<void> dispose() async {
    _timer?.cancel();
    if (_activeFlush != null) {
      await _activeFlush;
    }
    await flush();
    _needsFollowUpFlush = false;
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
      try {
        await _drainPending();
        if (!completer.isCompleted) {
          completer.complete();
        }
      } catch (error, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      } finally {
        if (identical(_activeFlush, future)) {
          _activeFlush = null;
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
        final failedEvent = batch[nextIndex];
        failedEvent.retryCount++;

        if (failedEvent.retryCount >= maxRetries) {
          // Drop the poison pill event by skipping it in the re-queue
          onEventDropped?.call(
            failedEvent.name,
            failedEvent.parameters,
            error,
            stackTrace,
          );
          nextIndex++;
        } else {
          // Backoff before retrying
          final delay = _calculateBackoff(failedEvent.retryCount);
          await Future.delayed(delay);
        }

        if (nextIndex < batch.length) {
          final remaining = batch.getRange(nextIndex, batch.length);
          _pending.insertAll(0, remaining);
          // Ensure we try to flush these re-queued events again
          _needsFollowUpFlush = true;
        }
      }
      onFlushError?.call(error, stackTrace);
      rethrow;
    }
  }

  Duration _calculateBackoff(int retryCount) {
    final delay = minRetryDelay * (1 << (retryCount - 1));
    return delay > maxRetryDelay ? maxRetryDelay : delay;
  }
}

final class _QueuedAnalyticsEvent {
  _QueuedAnalyticsEvent(this.name, this.parameters);

  final String name;
  final AnalyticsParams? parameters;
  int retryCount = 0;
}
