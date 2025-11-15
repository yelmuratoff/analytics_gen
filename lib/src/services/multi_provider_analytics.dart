import '../core/analytics_interface.dart';

/// Analytics service that forwards events to multiple providers.
///
/// Use this to send events to multiple analytics platforms simultaneously
/// (e.g., Firebase + Amplitude + Mixpanel).
///
/// Example:
/// ```
/// final multiProvider = MultiProviderAnalytics([
///   FirebaseAnalyticsService(firebase),
///   AmplitudeService(amplitude),
///   MixpanelService(mixpanel),
/// ]);
/// ```
final class MultiProviderAnalytics implements IAnalytics {
  final List<IAnalytics> _providers;
  final void Function(Object error, StackTrace stackTrace)? onError;
  /// Notifies observers when a specific provider fails so you can emit metrics/logs with context.
  final void Function(MultiProviderAnalyticsFailure failure)? onProviderFailure;

  MultiProviderAnalytics(
    this._providers, {
    this.onError,
    this.onProviderFailure,
  });

  @override
  void logEvent({
    required String name,
    AnalyticsParams? parameters,
  }) {
    for (final provider in _providers) {
      try {
        provider.logEvent(name: name, parameters: parameters);
      } catch (error, stackTrace) {
        final failure = MultiProviderAnalyticsFailure(
          provider: provider,
          providerName: provider.runtimeType.toString(),
          eventName: name,
          parameters: parameters,
          error: error,
          stackTrace: stackTrace,
        );
        onProviderFailure?.call(failure);
        if (onError != null) {
          onError!(failure.error, failure.stackTrace);
        }
      }
    }
  }

  /// Returns the number of configured providers
  int get providerCount => _providers.length;

  /// Adds a new provider to the list
  void addProvider(IAnalytics provider) {
    _providers.add(provider);
  }

  /// Removes a provider from the list
  void removeProvider(IAnalytics provider) {
    _providers.remove(provider);
  }
}

/// Metadata emitted whenever a provider fails inside [MultiProviderAnalytics].
final class MultiProviderAnalyticsFailure {
  /// Creates a failure report for the provided [provider].
  const MultiProviderAnalyticsFailure({
    required this.provider,
    required this.providerName,
    required this.eventName,
    required this.parameters,
    required this.error,
    required this.stackTrace,
  });

  /// Provider that threw while logging the event.
  final IAnalytics provider;

  /// A friendly name that can be used in logs/metrics (usually `provider.runtimeType`).
  final String providerName;

  /// The event name that failed to send.
  final String eventName;

  /// Parameters that were provided when logging the event.
  final AnalyticsParams? parameters;

  /// The runtime error raised by the provider.
  final Object error;

  /// Stack trace emitted by the provider.
  final StackTrace stackTrace;
}
