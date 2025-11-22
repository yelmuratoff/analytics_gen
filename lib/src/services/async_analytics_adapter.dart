import '../core/analytics_interface.dart';
import '../core/async_analytics_interface.dart';

/// Adapter that wraps a synchronous `IAnalytics` implementation and exposes
/// an asynchronous `IAsyncAnalytics` API. This is useful when integrating with
/// async pipelines where callers prefer to await delivery.
final class AsyncAnalyticsAdapter implements IAsyncAnalytics {
  /// Creates a new async adapter.
  AsyncAnalyticsAdapter(this._delegate);
  final IAnalytics _delegate;

  @override
  Future<void> logEventAsync({
    required String name,
    AnalyticsParams? parameters,
  }) async {
    // Execute sync logging in a microtask to avoid blocking the caller's frame.
    await Future.microtask(
        () => _delegate.logEvent(name: name, parameters: parameters));
  }
}
