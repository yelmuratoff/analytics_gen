import 'dart:async';

/// Simple scheduler that debounces watch-mode regenerations.
final class WatchRegenerationScheduler {
  /// Creates a new watch regeneration scheduler.
  WatchRegenerationScheduler({
    required this.onGenerate,
    Duration? debounceDuration,
  }) : debounceDuration = debounceDuration ?? const Duration(milliseconds: 350);

  /// How long to wait after the last file event before regenerating.
  final Duration debounceDuration;

  /// Callback invoked once the debounce window closes.
  final Future<void> Function() onGenerate;

  Timer? _timer;
  bool _pending = false;
  bool _isRunning = false;

  /// Schedule a regeneration run.
  void schedule() {
    _pending = true;
    _timer?.cancel();
    _timer = Timer(debounceDuration, _flush);
  }

  void _flush() {
    if (!_pending) return;
    if (_isRunning) {
      _pending = true;
      return;
    }

    _pending = false;
    _isRunning = true;

    onGenerate().whenComplete(() {
      _isRunning = false;
      if (_pending) {
        schedule();
      }
    });
  }

  /// Disposes active timers.
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
