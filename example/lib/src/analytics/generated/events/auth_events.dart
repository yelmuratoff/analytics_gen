// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import
// ignore_for_file: directives_ordering, unnecessary_string_interpolations
// coverage:ignore-file

import 'package:analytics_gen/analytics_gen.dart';

/// Enum for login_v2 - login-method
enum AnalyticsAuthLoginV2LoginMethodEnum {
  email('email'),
  google('google'),
  apple('apple');

  final String value;
  const AnalyticsAuthLoginV2LoginMethodEnum(this.value);
}

/// Generated mixin for auth analytics events
mixin AnalyticsAuth on AnalyticsBase {
  @Deprecated('Use logAuthLoginV2 instead.')
  /// User logs in to the application
  ///
  /// Parameters:
  /// - `method`: string - Login method (email, google, apple)
  void logAuthLogin({required String method}) {
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
  /// - `login-method`: AnalyticsAuthLoginV2LoginMethodEnum - Login method v2 (email, google, apple)
  void logAuthLoginV2({
    required AnalyticsAuthLoginV2LoginMethodEnum loginMethod,
  }) {
    logger.logEvent(
      name: "auth: login_v2",
      parameters: <String, Object?>{
        'description': 'User logs in to the application (v2)',
        "login-method": loginMethod.value,
      },
    );
  }

  /// User logs out
  ///
  void logAuthLogout() {
    logger.logEvent(
      name: "auth: logout",
      parameters: <String, Object?>{'description': 'User logs out'},
    );
  }

  @Deprecated(
    'This event uses string interpolation in its name, which causes high cardinality. Use parameters instead.',
  )
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
  void logAuthSignup({required String method, String? referralCode}) {
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
