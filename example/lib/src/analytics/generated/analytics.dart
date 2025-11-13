import 'package:analytics_gen/analytics_gen.dart';

import 'generated_events.dart';

/// Main Analytics singleton class.
///
/// Automatically generated with all domain mixins.
/// Initialize once at app startup, then use throughout your app.
///
/// Example:
/// ```dart
/// Analytics.initialize(YourAnalyticsService());
/// Analytics.instance.logAuthLogin(method: "email");
/// ```
final class Analytics extends AnalyticsBase with AnalyticsAuth, AnalyticsPurchase, AnalyticsScreen
{
  static final Analytics _instance = Analytics._internal();
  Analytics._internal();

  /// Access the singleton instance
  static Analytics get instance => _instance;

  late IAnalytics _analytics;

  /// Initialize analytics with your provider
  ///
  /// Call this once at app startup before using any analytics methods.
  static void initialize(IAnalytics analytics) {
    _instance._analytics = analytics;
  }

  @override
  IAnalytics get logger => _analytics;
}

