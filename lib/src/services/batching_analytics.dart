import 'dart:async';

import '../core/analytics_interface.dart';
import '../core/async_analytics_interface.dart';

typedef BatchFlushErrorHandler = void Function(
  Object error,
  StackTrace stackTrace,
);

/// Buffers analytics events and flushes them in batches to an async delegate.
///
/// Use this wrapper when you need to control network usage (cellular metering,
/// flaky providers, cold starts) without changing the synchronous
/// `IAnalytics.logEvent` contract exposed to the rest of the app.
final class BatchingAnalytics implements IAnalytics {
  BatchingAnalytics({
    required IAsyncAnalytics delegate,
    this.maxBatchSize = 20,
    Duration? flushInterval,
    this.onFlushError,
  })  : assert(maxBatchSize > 0, 'maxBatchSize must be greater than zero.'),
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
  final int maxBatchSize;
  final BatchFlushErrorHandler? onFlushError;

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
        if (propagateErrors) {
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
        } else {
          if (!completer.isCompleted) {
            completer.complete();
          }
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

    if (!propagateErrors) {
      return future.catchError((_) {});
    }

    return future;
  }

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
        final remaining = batch.getRange(nextIndex, batch.length);
        _pending.insertAll(0, remaining);
      }
      onFlushError?.call(error, stackTrace);
      rethrow;
    }
  }
}

final class _QueuedAnalyticsEvent {
  _QueuedAnalyticsEvent(this.name, this.parameters);

  final String name;
  final AnalyticsParams? parameters;
}
