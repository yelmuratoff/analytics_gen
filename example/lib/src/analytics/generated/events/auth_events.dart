// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import
// ignore_for_file: directives_ordering, unnecessary_string_interpolations
// coverage:ignore-file

import 'package:analytics_gen/analytics_gen.dart';

/// Generated mixin for auth analytics events
mixin AnalyticsAuth on AnalyticsBase {
  /// User logs in to the application
  ///
  /// Parameters:
  /// - `method`: string - Login method (email, google, apple)
  void logAuthLogin({
    required String method,
  }) {
    logger.logEvent(
      name: "auth: login",
      parameters: <String, Object?>{
        "method": method,
      },
    );
  }

  /// User logs out
  ///
  void logAuthLogout() {
    logger.logEvent(
      name: "auth: logout",
      parameters: const {},
    );
  }

  /// User creates a new account
  ///
  /// Parameters:
  /// - `method`: string
  /// - `referral_code`: string? - Optional referral code used during signup
  void logAuthSignup({
    required String method,
    String? referralCode,
  }) {
    logger.logEvent(
      name: "auth: signup",
      parameters: <String, Object?>{
        "method": method,
        if (referralCode != null) "referral_code": referralCode,
      },
    );
  }

}
