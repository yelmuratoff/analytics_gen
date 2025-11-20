// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated at: 2025-11-20T17:08:29.484490
// ignore_for_file: type=lint, unused_import
// ignore_for_file: directives_ordering, unnecessary_string_interpolations
// coverage:ignore-file

import 'package:analytics_gen/analytics_gen.dart';

/// Generated mixin for screen analytics events
mixin AnalyticsScreen on AnalyticsBase {
  /// Legacy backend identifier kept for parity
  ///
  /// Parameters:
  /// - `legacy-screen-code`: string - Three-letter code provided by data team
  void logScreenLegacyView({
    required String legacyScreenCode,
  }) {

    logger.logEvent(
      name: "Screen: Legacy",
      parameters: <String, Object?>{
        'description': 'Legacy backend identifier kept for parity',
        "legacy-screen-code": legacyScreenCode,
      },
    );
  }

  @Deprecated('This event uses string interpolation in its name, which causes high cardinality. Use parameters instead.')
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
        'description': 'User views a screen',
        if (durationMs != null) "duration_ms": durationMs,
        if (previousScreen != null) "previous_screen": previousScreen,
        "screen_name": screenName,
      },
    );
  }

}
