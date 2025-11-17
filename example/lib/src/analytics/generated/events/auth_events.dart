// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import
// ignore_for_file: directives_ordering, unnecessary_string_interpolations
// coverage:ignore-file

import 'package:analytics_gen/analytics_gen.dart';

/// Generated mixin for auth analytics events
mixin AnalyticsAuth on AnalyticsBase {
  @Deprecated('Use logAuthLoginV2 instead.')
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
        'description': 'User logs in to the application',
        "method": method,
      },
    );
  }

  /// User logs in to the application (v2)
  ///
  /// Parameters:
  /// - `method`: string - Login method v2 (email, google, apple)
  void logAuthLoginV2({
    required String method,
  }) {

    logger.logEvent(
      name: "auth: login_v2",
      parameters: <String, Object?>{
        'description': 'User logs in to the application (v2)',
        "method": method,
      },
    );
  }

  /// User logs out
  ///
  void logAuthLogout() {
    logger.logEvent(
      name: "auth: logout",
      parameters: <String, Object?>{
        'description': 'User logs out',
      },
    );
  }

  /// When user logs in via phone
  ///
  /// Parameters:
  /// - `user_exists`: bool? - Whether the user exists or not
  void logAuthPhoneLogin({
    bool? userExists,
  }) {

    logger.logEvent(
      name: "Auth: Phone",
      parameters: <String, Object?>{
        'description': 'When user logs in via phone',
        if (userExists != null) "user_exists": userExists,
      },
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
        'description': 'User creates a new account',
        "method": method,
        if (referralCode != null) "referral_code": referralCode,
      },
    );
  }

}
