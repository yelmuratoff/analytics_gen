// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import
// ignore_for_file: directives_ordering, unnecessary_string_interpolations
// coverage:ignore-file

import 'package:analytics_gen/analytics_gen.dart';

/// Generated mixin for screen analytics events
mixin AnalyticsScreen on AnalyticsBase {
  /// User views a screen
  ///
  /// Parameters:
  /// - `screen_name`: string
  /// - `previous_screen`: string? - Name of the previous screen
  /// - `duration_ms`: int? - Time spent on previous screen in milliseconds
  void logScreenView({
    required String screenName,
    String? previousScreen,
    int? durationMs,
  }) {
    logger.logEvent(
      name: 'Screen: View',
      parameters: <String, dynamic>{
        'screen_name': screenName,
        if (previousScreen != null) 'previous_screen': previousScreen,
        if (durationMs != null) 'duration_ms': durationMs,
      },
    );
  }

}
