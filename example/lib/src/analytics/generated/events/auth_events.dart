// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated at: 2025-11-20T16:49:28.315171
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
  /// - `login-method`: string - Login method v2 (email, google, apple)
  void logAuthLoginV2({
    required String loginMethod,
  }) {

    logger.logEvent(
      name: "auth: login_v2",
      parameters: <String, Object?>{
        'description': 'User logs in to the application (v2)',
        "login-method": loginMethod,
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

  @Deprecated('This event uses string interpolation in its name, which causes high cardinality. Use parameters instead.')
  /// When user logs in via phone
  ///
  /// Parameters:
  /// - `phone_country`: string - ISO country code for the dialed number
  /// - `tracking-token`: string - Legacy token kept for backend reconciliation
  /// - `user_exists`: bool? - Whether the user exists or not
  void logAuthPhoneLogin({
    required String phoneCountry,
    required String trackingToken,
    bool? userExists,
  }) {

    logger.logEvent(
      name: "Auth: Phone ${phoneCountry}",
      parameters: <String, Object?>{
        'description': 'When user logs in via phone',
        "phone_country": phoneCountry,
        "tracking-token": trackingToken,
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
