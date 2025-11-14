import 'analytics_interface.dart';

/// Base class for generated analytics mixins.
///
/// All generated domain mixins will be mixed onto this base class,
/// which provides access to the underlying [IAnalytics] implementation.
abstract class AnalyticsBase {
  /// The analytics service implementation used to log events.
  ///
  /// Generated mixins call [logger.logEvent] to send events to
  /// the configured analytics provider.
  IAnalytics get logger;
}

/// Ensures analytics has been initialized before logging events.
IAnalytics ensureAnalyticsInitialized(IAnalytics? analytics) {
  if (analytics == null) {
    throw StateError(
      'Analytics.initialize(...) must be called before logging events.',
    );
  }
  return analytics;
}
