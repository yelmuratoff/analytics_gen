import 'analytics_capabilities.dart';
import 'analytics_interface.dart';

/// Base class for generated analytics mixins.
///
/// All generated domain mixins will be mixed onto this base class,
/// which provides access to the underlying [IAnalytics] implementation.
abstract class AnalyticsBase {
  /// Creates a new analytics base.
  const AnalyticsBase();

  /// The analytics service implementation used to log events.
  ///
  /// Generated mixins call [IAnalytics.logEvent] to send events to
  /// the configured analytics provider.
  IAnalytics get logger;

  /// Exposes provider-specific capabilities (user properties, timed events, etc.).
  ///
  /// Subclasses can override this getter to wire custom resolvers. By default
  /// it returns an empty resolver.
  AnalyticsCapabilityResolver get capabilities =>
      const NullCapabilityResolver();

  /// Convenience helper for retrieving a typed capability.
  T? capability<T extends AnalyticsCapability>(CapabilityKey<T> key) {
    return capabilities.getCapability(key);
  }

  /// Sanitizes a value for HTML context (escapes <, >, &, ", ').
  String sanitizeHtml(Object? value) {
    if (value == null) return '';
    return value
        .toString()
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Sanitizes a value for SQL context (escapes single quotes).
  String sanitizeSql(Object? value) {
    if (value == null) return '';
    return value.toString().replaceAll("'", "''");
  }
}

/// Ensures analytics has been initialized before logging events.
IAnalytics ensureAnalyticsInitialized(IAnalytics? analytics) {
  if (analytics == null) {
    throw StateError(
      'Analytics.initialize(...) must be called before logging events.\n'
      'Ensure you call Analytics.initialize() in your main() function or before using any analytics features.',
    );
  }
  return analytics;
}
