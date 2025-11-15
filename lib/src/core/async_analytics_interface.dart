import 'analytics_interface.dart';

/// Async analytics API used for providers that require awaitable delivery.
abstract interface class IAsyncAnalytics {
  /// Logs an analytics event asynchronously.
  Future<void> logEventAsync({
    required String name,
    AnalyticsParams? parameters,
  });
}
