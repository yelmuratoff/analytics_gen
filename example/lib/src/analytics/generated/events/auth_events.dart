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
  /// - `method`: String - Login method (email, google, apple)
  void logAuthLogin({
    required String method,
    Map<String, Object?>? parameters,
  }) {

    final eventParameters = parameters ?? <String, Object?>{
      'description': 'User logs in to the application',
      "method": method,
    };

    logger.logEvent(
      name: "auth: login",
      parameters: eventParameters,
    );
  }

  /// User logs in to the application (v2)
  ///
  /// Parameters:
  /// - `login-method`: AnalyticsAuthLoginV2LoginMethodEnum - Login method v2 (email, google, apple)
  /// - `session_id`: String - Unique identifier for the current session.
  void logAuthLoginV2({
    required AnalyticsAuthLoginV2LoginMethodEnum loginMethod,
    required String sessionId,
    Map<String, Object?>? parameters,
  }) {

    final eventParameters = parameters ?? <String, Object?>{
      'description': 'User logs in to the application (v2)',
      "login-method": loginMethod.value,
      "session_id": sessionId,
    };

    logger.logEvent(
      name: "auth: login_v2",
      parameters: eventParameters,
    );

    // Dual-write to: auth.login
    logAuthLogin(method: loginMethod.value, parameters: parameters);
  }

  /// User logs out
  ///
  void logAuthLogout({Map<String, Object?>? parameters}) {
    final eventParameters = parameters ?? <String, Object?>{
      'description': 'User logs out',
    };

    logger.logEvent(
      name: "auth: logout",
      parameters: eventParameters,
    );
  }

  @Deprecated('This event uses string interpolation in its name, which causes high cardinality. Use parameters instead.')
  /// When user logs in via phone
  ///
  /// Parameters:
  /// - `phone_country`: String - ISO country code for the dialed number
  /// - `tracking-token`: String - Legacy token kept for backend reconciliation
  /// - `user_exists`: bool? - Whether the user exists or not
  void logAuthPhoneLogin({
    required String phoneCountry,
    required String trackingToken,
    bool? userExists,
    Map<String, Object?>? parameters,
  }) {

    final eventParameters = parameters ?? <String, Object?>{
      'description': 'When user logs in via phone',
      "phone_country": phoneCountry,
      "tracking-token": trackingToken,
      if (userExists != null) "user_exists": userExists,
    };

    logger.logEvent(
      name: "Auth: Phone ${phoneCountry}",
      parameters: eventParameters,
    );
  }

  /// User creates a new account
  ///
  /// Parameters:
  /// - `method`: String
  /// - `referral_code`: String? - Optional referral code used during signup
  void logAuthSignup({
    required String method,
    String? referralCode,
    Map<String, Object?>? parameters,
  }) {

    if (referralCode != null && !RegExp(r'^[A-Z0-9]{6}$').hasMatch(referralCode)) {
      throw ArgumentError.value(
        referralCode,
        'referralCode',
        'must match regex ^[A-Z0-9]{6}\$',
      );
    }
    final eventParameters = parameters ?? <String, Object?>{
      'description': 'User creates a new account',
      "method": method,
      if (referralCode != null) "referral_code": referralCode,
    };

    logger.logEvent(
      name: "auth: signup",
      parameters: eventParameters,
    );
  }

}
