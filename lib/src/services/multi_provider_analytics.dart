import 'dart:async';

import '../core/analytics_capabilities.dart';
import '../core/analytics_interface.dart';
import '../core/async_analytics_interface.dart';
import '../util/logger.dart';

/// Function used to check whether an event (name + params) should be
/// forwarded to a particular provider.
typedef EventPredicate = bool Function(String name, AnalyticsParams? params);

/// Analytics service that forwards events to multiple providers.
///
/// This class is immutable and implements both [IAnalytics] (sync) and
/// [IAsyncAnalytics] (async) logging interfaces — callers can use the
/// synchronous `logEvent` or the asynchronous `logEventAsync` when awaiting
/// provider delivery is required.
///
/// This class is immutable. Use [addProvider] or [removeProvider]
/// to create new instances with modified provider lists.
///
/// ## Sync vs Async Logging
///
/// This class supports both synchronous ([logEvent]) and asynchronous
/// ([logEventAsync]) logging.
///
/// ### When to use [logEvent] (Synchronous)
/// Use this for standard app usage (e.g. UI interactions). It wraps all provider
/// calls in microtasks to ensure the UI thread is not blocked, even if a provider
/// performs expensive synchronous work. Errors are reported via [onError] or
/// [onProviderFailure].
///
/// ### When to use [logEventAsync] (Asynchronous)
/// Use this when you need to ensure delivery before proceeding, such as:
/// * App shutdown or specific cleanup logic.
/// * Background tasks where the process might be killed.
/// * Tests where you need deterministic execution order.
///
/// If a provider implements [IAsyncAnalytics], this method awaits its completion.
/// If a provider is synchronous, it is still wrapped in a microtask but awaited.
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
final class MultiProviderAnalytics
    implements IAnalytics, IAsyncAnalytics, AnalyticsCapabilityProvider {
  /// Creates an immutable multi-provider analytics service.
  ///
  /// The [providers] list is copied and made unmodifiable to ensure immutability.
  MultiProviderAnalytics(
    List<IAnalytics> providers, {
    this.onError,
    this.onProviderFailure,
    Map<IAnalytics, EventPredicate?>? providerFilters,
    Logger? logger,
  })  : _providers = List.unmodifiable(providers),
        _providerFilters = Map.unmodifiable(providerFilters ?? const {}),
        _logger = logger ?? const NoOpLogger();
  final List<IAnalytics> _providers;

  /// Notifies observers when any provider fails.
  final void Function(Object error, StackTrace stackTrace)? onError;

  /// Notifies observers when a specific provider fails.
  /// Use this for metrics, logging, or alerting with full context.
  final void Function(MultiProviderAnalyticsFailure failure)? onProviderFailure;

  /// Optional per-provider filters: if a filter returns false the provider
  /// will not receive that event.
  final Map<IAnalytics, EventPredicate?> _providerFilters;

  final Logger _logger;

  @override
  AnalyticsCapabilityResolver get capabilityResolver =>
      _MultiProviderCapabilityResolver(_providers);

  @override
  void logEvent({
    required String name,
    AnalyticsParams? parameters,
  }) {
    for (final provider in _providers) {
      final predicate = _providerFilters[provider];
      if (predicate != null && !predicate(name, parameters)) continue;

      scheduleMicrotask(() {
        try {
          provider.logEvent(name: name, parameters: parameters);
        } catch (error, stackTrace) {
          _handleProviderFailure(provider, name, parameters, error, stackTrace);
        }
      });
    }
  }

  @override
  Future<void> logEventAsync({
    required String name,
    AnalyticsParams? parameters,
  }) async {
    final List<Future<void>> pending = [];

    for (final provider in _providers) {
      final predicate = _providerFilters[provider];
      if (predicate != null && !predicate(name, parameters)) continue;

      if (provider is IAsyncAnalytics) {
        // If the provider offers an async API, await it and map any errors
        // back through the failure hooks.
        final asyncProvider = provider as IAsyncAnalytics;
        pending.add(asyncProvider
            .logEventAsync(name: name, parameters: parameters)
            .catchError((error, stackTrace) {
          _handleProviderFailure(
              provider, name, parameters, error, stackTrace as StackTrace);
        }));
      } else {
        // Wrap sync logging in a microtask so async callers don't block.
        pending.add(Future.microtask(
                () => provider.logEvent(name: name, parameters: parameters))
            .catchError((error, stackTrace) {
          _handleProviderFailure(
              provider, name, parameters, error, stackTrace as StackTrace);
        }));
      }
    }

    if (pending.isEmpty) return;

    // Wait for all providers to complete but don't throw if one fails — errors
    // are already reported to onProviderFailure and onError via catchError wrappers above.
    await Future.wait(pending);
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

    if (onProviderFailure == null && onError == null) {
      _logger.warning(
        'Provider failure (${failure.providerName}) for event "${failure.eventName}": ${failure.error}',
      );
    }
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
    final newProviderFilters =
        Map<IAnalytics, EventPredicate?>.from(_providerFilters);
    if (providerFilter != null) {
      newProviderFilters[provider] = providerFilter;
    }

    return MultiProviderAnalytics(
      newProviders,
      onError: onError,
      onProviderFailure: onProviderFailure,
      providerFilters: newProviderFilters,
      logger: _logger,
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
    final newProviderFilters =
        Map<IAnalytics, EventPredicate?>.from(_providerFilters);
    newProviderFilters.remove(provider);

    return MultiProviderAnalytics(
      newProviders,
      onError: onError,
      onProviderFailure: onProviderFailure,
      providerFilters: newProviderFilters,
      logger: _logger,
    );
  }

  /// Returns a new instance without providers of type [T].
  ///
  /// This method does not mutate the current instance.
  ///
  /// Example:
  /// ```dart
  /// final updated = analytics.removeProviderByType<FirebaseAnalyticsService>();
  /// ```
  MultiProviderAnalytics removeProviderByType<T extends IAnalytics>() {
    final newProviders = _providers.where((p) => p is! T).toList();
    final newProviderFilters =
        Map<IAnalytics, EventPredicate?>.from(_providerFilters);
    newProviderFilters.removeWhere((key, _) => key is T);

    return MultiProviderAnalytics(
      newProviders,
      onError: onError,
      onProviderFailure: onProviderFailure,
      providerFilters: newProviderFilters,
      logger: _logger,
    );
  }
}

final class _MultiProviderCapabilityResolver
    implements AnalyticsCapabilityResolver {
  _MultiProviderCapabilityResolver(this.providers);
  final List<IAnalytics> providers;

  @override
  T? getCapability<T extends AnalyticsCapability>(CapabilityKey<T> key) {
    // Returns the first provider that supports the requested capability.
    // If multiple providers support the same capability, the one that appears
    // earlier in the providers list takes precedence.
    for (final provider in providers) {
      final resolver = analyticsCapabilitiesFor(provider);
      final capability = resolver.getCapability(key);
      if (capability != null) return capability;
    }
    return null;
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
