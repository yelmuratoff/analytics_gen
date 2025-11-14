import '../core/analytics_interface.dart';

/// Analytics service that forwards events to multiple providers.
///
/// Use this to send events to multiple analytics platforms simultaneously
/// (e.g., Firebase + Amplitude + Mixpanel).
///
/// Example:
/// ```dart
/// final multiProvider = MultiProviderAnalytics([
///   FirebaseAnalyticsService(firebase),
///   AmplitudeService(amplitude),
///   MixpanelService(mixpanel),
/// ]);
/// ```
final class MultiProviderAnalytics implements IAnalytics {
  final List<IAnalytics> _providers;
  final void Function(Object error, StackTrace stackTrace)? onError;

  MultiProviderAnalytics(
    this._providers, {
    this.onError,
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
        if (onError != null) {
          onError!(error, stackTrace);
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
