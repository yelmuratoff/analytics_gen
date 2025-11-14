/// Common type used for analytics event parameters.
///
/// Values should be JSON-serializable (String, num, bool, null, List, Map),
/// or simple objects that your analytics provider knows how to handle.
typedef AnalyticsParams = Map<String, Object?>;

/// Interface for analytics service implementations.
///
/// Implement this interface to integrate with any analytics provider
/// (Firebase, Amplitude, Mixpanel, etc.).
abstract interface class IAnalytics {
  /// Logs an analytics event with optional parameters.
  ///
  /// [name] is the event name (e.g., "Auth: Login").
  /// [parameters] contains event-specific data in snake_case format.
  void logEvent({
    required String name,
    AnalyticsParams? parameters,
  });
}
