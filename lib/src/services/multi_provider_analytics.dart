import 'dart:io';

import '../core/analytics_interface.dart';

/// Function used to check whether an event (name + params) should be
/// forwarded to a particular provider.
typedef EventPredicate = bool Function(String name, AnalyticsParams? params);

/// Analytics service that forwards events to multiple providers.
///
/// This class is immutable. Use [addProvider] or [removeProvider]
/// to create new instances with modified provider lists.
///
/// Example:
/// ```dart
/// final multiProvider = MultiProviderAnalytics([
///   FirebaseAnalyticsService(firebase),
///   AmplitudeService(amplitude),
///   MixpanelService(mixpanel),
/// ]);
///
/// // Functional updates (immutable)
/// final updated = multiProvider.addProvider(SegmentService(segment));
/// ```
final class MultiProviderAnalytics implements IAnalytics {
  final List<IAnalytics> _providers;
  final void Function(Object error, StackTrace stackTrace)? onError;

  /// Notifies observers when a specific provider fails.
  /// Use this for metrics, logging, or alerting with full context.
  final void Function(MultiProviderAnalyticsFailure failure)? onProviderFailure;

  /// Optional per-provider filters: if a filter returns false the provider
  /// will not receive that event.
  final Map<IAnalytics, EventPredicate?> _providerFilters;

  /// Creates an immutable multi-provider analytics service.
  ///
  /// The [providers] list is copied and made unmodifiable to ensure immutability.
  MultiProviderAnalytics(
    List<IAnalytics> providers, {
    this.onError,
    this.onProviderFailure,
    Map<IAnalytics, EventPredicate?>? providerFilters,
  })  : _providers = List.unmodifiable(providers),
        _providerFilters = Map.unmodifiable(providerFilters ?? const {});

  @override
  void logEvent({
    required String name,
    AnalyticsParams? parameters,
  }) {
    for (final provider in _providers) {
      final predicate = _providerFilters[provider];
      if (predicate != null && !predicate(name, parameters)) continue;
      try {
        provider.logEvent(name: name, parameters: parameters);
      } on SocketException catch (error, stackTrace) {
        // Expected: Network failures - continue with other providers
        _handleProviderFailure(provider, name, parameters, error, stackTrace);
      } on FormatException catch (error, stackTrace) {
        // Expected: Validation errors - continue with other providers
        _handleProviderFailure(provider, name, parameters, error, stackTrace);
      } catch (error, stackTrace) {
        // Unexpected: Provider bugs - log and continue
        _handleProviderFailure(provider, name, parameters, error, stackTrace);

        // In debug mode, log unexpected errors with more detail
        assert(() {
          // Log to console in debug builds
          // ignore: avoid_print
          print(
            '[Analytics] Unexpected error in ${provider.runtimeType}.logEvent:\n'
            '  Error: $error\n'
            '  Event: $name\n'
            '  Parameters: $parameters\n'
            '  Stack trace: $stackTrace',
          );
          return true;
        }());
      }
    }
  }

  void _handleProviderFailure(
    IAnalytics provider,
    String eventName,
    AnalyticsParams? parameters,
    Object error,
    StackTrace stackTrace,
  ) {
    final failure = MultiProviderAnalyticsFailure(
      provider: provider,
      providerName: provider.runtimeType.toString(),
      eventName: eventName,
      parameters: parameters,
      error: error,
      stackTrace: stackTrace,
    );

    onProviderFailure?.call(failure);
    onError?.call(failure.error, failure.stackTrace);
  }

  /// Returns the number of configured providers.
  int get providerCount => _providers.length;

  /// Returns a new instance with the added provider (functional update).
  ///
  /// This method does not mutate the current instance.
  ///
  /// Example:
  /// ```dart
  /// final updated = analytics.addProvider(NewProvider());
  /// ```
  MultiProviderAnalytics addProvider(
    IAnalytics provider, {
    EventPredicate? providerFilter,
  }) {
    final newProviders = [..._providers, provider];
    final newProviderFilters = Map<IAnalytics, EventPredicate?>.from(_providerFilters);
    if (providerFilter != null) {
      newProviderFilters[provider] = providerFilter;
    }

    return MultiProviderAnalytics(
      newProviders,
      onError: onError,
      onProviderFailure: onProviderFailure,
      providerFilters: newProviderFilters,
    );
  }

  /// Returns a new instance without the specified provider (functional update).
  ///
  /// This method does not mutate the current instance.
  ///
  /// Example:
  /// ```dart
  /// final updated = analytics.removeProvider(oldProvider);
  /// ```
  MultiProviderAnalytics removeProvider(IAnalytics provider) {
    final newProviders = _providers.where((p) => p != provider).toList();
    final newProviderFilters = Map<IAnalytics, EventPredicate?>.from(_providerFilters);
    newProviderFilters.remove(provider);

    return MultiProviderAnalytics(
      newProviders,
      onError: onError,
      onProviderFailure: onProviderFailure,
      providerFilters: newProviderFilters,
    );
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
