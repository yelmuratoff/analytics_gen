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
  /// - `duration_ms`: int? - Time spent on previous screen in milliseconds
  /// - `previous_screen`: string? - Name of the previous screen
  /// - `screen_name`: string
  void logScreenView({
    int? durationMs,
    String? previousScreen,
    required String screenName,
  }) {

    logger.logEvent(
      name: "Screen: ${screenName}",
      parameters: <String, Object?>{
        if (durationMs != null) "duration_ms": durationMs,
        if (previousScreen != null) "previous_screen": previousScreen,
        "screen_name": screenName,
      },
    );
  }

}
