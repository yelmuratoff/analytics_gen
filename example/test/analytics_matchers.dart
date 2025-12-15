// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import
// ignore_for_file: directives_ordering, unnecessary_string_interpolations
// coverage:ignore-file

import 'package:test/test.dart';
import '../lib/src/analytics/generated/generated_events.dart';

/// Key-value pair for event parameters
typedef EventParams = Map<String, Object?>;

// Domain: auth
/// Matcher for auth.login
Matcher isAuthLogin({Object? method}) {
  return predicate((item) {
    if (item is! Map) return false;
    final Map<String, dynamic> params = Map.from(item);

    if (method != null) {
      if (!params.containsKey("method")) return false;
      final actual = params["method"];
      if (method is Matcher) {
        if (!method.matches(actual, {})) return false;
      } else {
        if (actual != method) return false;
      }
    }
    return true;
  });
}

/// Matcher for auth.login_v2
Matcher isAuthLoginV2({Object? loginMethod, Object? sessionId}) {
  return predicate((item) {
    if (item is! Map) return false;
    final Map<String, dynamic> params = Map.from(item);

    if (loginMethod != null) {
      if (!params.containsKey("login-method")) return false;
      final actual = params["login-method"];
      if (loginMethod is Matcher) {
        if (!loginMethod.matches(actual, {})) return false;
      } else {
        if (loginMethod is AnalyticsAuthLoginV2LoginMethodEnum) {
          if (actual != loginMethod.value) return false;
        } else {
          if (actual != loginMethod) return false;
        }
      }
    }
    if (sessionId != null) {
      if (!params.containsKey("session_id")) return false;
      final actual = params["session_id"];
      if (sessionId is Matcher) {
        if (!sessionId.matches(actual, {})) return false;
      } else {
        if (actual != sessionId) return false;
      }
    }
    return true;
  });
}

/// Matcher for auth.logout
Matcher isAuthLogout() {
  return predicate((item) {
    if (item is! Map) return false;

    return true;
  });
}

/// Matcher for auth.phone_login
Matcher isAuthPhoneLogin({
  Object? phoneCountry,
  Object? trackingToken,
  Object? userExists,
}) {
  return predicate((item) {
    if (item is! Map) return false;
    final Map<String, dynamic> params = Map.from(item);

    if (phoneCountry != null) {
      if (!params.containsKey("phone_country")) return false;
      final actual = params["phone_country"];
      if (phoneCountry is Matcher) {
        if (!phoneCountry.matches(actual, {})) return false;
      } else {
        if (actual != phoneCountry) return false;
      }
    }
    if (trackingToken != null) {
      if (!params.containsKey("tracking-token")) return false;
      final actual = params["tracking-token"];
      if (trackingToken is Matcher) {
        if (!trackingToken.matches(actual, {})) return false;
      } else {
        if (actual != trackingToken) return false;
      }
    }
    if (userExists != null) {
      if (!params.containsKey("user_exists")) return false;
      final actual = params["user_exists"];
      if (userExists is Matcher) {
        if (!userExists.matches(actual, {})) return false;
      } else {
        if (actual != userExists) return false;
      }
    }
    return true;
  });
}

/// Matcher for auth.signup
Matcher isAuthSignup({Object? method, Object? referralCode}) {
  return predicate((item) {
    if (item is! Map) return false;
    final Map<String, dynamic> params = Map.from(item);

    if (method != null) {
      if (!params.containsKey("method")) return false;
      final actual = params["method"];
      if (method is Matcher) {
        if (!method.matches(actual, {})) return false;
      } else {
        if (actual != method) return false;
      }
    }
    if (referralCode != null) {
      if (!params.containsKey("referral_code")) return false;
      final actual = params["referral_code"];
      if (referralCode is Matcher) {
        if (!referralCode.matches(actual, {})) return false;
      } else {
        if (actual != referralCode) return false;
      }
    }
    return true;
  });
}

/// Matcher for auth.verify_user
Matcher isAuthVerifyUser({Object? localStatus, Object? status}) {
  return predicate((item) {
    if (item is! Map) return false;
    final Map<String, dynamic> params = Map.from(item);

    if (localStatus != null) {
      if (!params.containsKey("local_status")) return false;
      final actual = params["local_status"];
      if (localStatus is Matcher) {
        if (!localStatus.matches(actual, {})) return false;
      } else {
        if (actual != localStatus) return false;
      }
    }
    if (status != null) {
      if (!params.containsKey("status")) return false;
      final actual = params["status"];
      if (status is Matcher) {
        if (!status.matches(actual, {})) return false;
      } else {
        if (actual != status) return false;
      }
    }
    return true;
  });
}

// Domain: purchase
/// Matcher for purchase.cancelled
Matcher isPurchaseCancelled({Object? productId, Object? reason}) {
  return predicate((item) {
    if (item is! Map) return false;
    final Map<String, dynamic> params = Map.from(item);

    if (productId != null) {
      if (!params.containsKey("product_id")) return false;
      final actual = params["product_id"];
      if (productId is Matcher) {
        if (!productId.matches(actual, {})) return false;
      } else {
        if (actual != productId) return false;
      }
    }
    if (reason != null) {
      if (!params.containsKey("reason")) return false;
      final actual = params["reason"];
      if (reason is Matcher) {
        if (!reason.matches(actual, {})) return false;
      } else {
        if (actual != reason) return false;
      }
    }
    return true;
  });
}

/// Matcher for purchase.completed
Matcher isPurchaseCompleted({
  Object? currencyCode,
  Object? price,
  Object? productId,
  Object? quantity,
}) {
  return predicate((item) {
    if (item is! Map) return false;
    final Map<String, dynamic> params = Map.from(item);

    if (currencyCode != null) {
      if (!params.containsKey("currency-code")) return false;
      final actual = params["currency-code"];
      if (currencyCode is Matcher) {
        if (!currencyCode.matches(actual, {})) return false;
      } else {
        if (actual != currencyCode) return false;
      }
    }
    if (price != null) {
      if (!params.containsKey("amount_value")) return false;
      final actual = params["amount_value"];
      if (price is Matcher) {
        if (!price.matches(actual, {})) return false;
      } else {
        if (actual != price) return false;
      }
    }
    if (productId != null) {
      if (!params.containsKey("product_id")) return false;
      final actual = params["product_id"];
      if (productId is Matcher) {
        if (!productId.matches(actual, {})) return false;
      } else {
        if (actual != productId) return false;
      }
    }
    if (quantity != null) {
      if (!params.containsKey("quantity")) return false;
      final actual = params["quantity"];
      if (quantity is Matcher) {
        if (!quantity.matches(actual, {})) return false;
      } else {
        if (actual != quantity) return false;
      }
    }
    return true;
  });
}

// Domain: screen
/// Matcher for screen.legacy_view
Matcher isScreenLegacyView({Object? legacyScreenCode}) {
  return predicate((item) {
    if (item is! Map) return false;
    final Map<String, dynamic> params = Map.from(item);

    if (legacyScreenCode != null) {
      if (!params.containsKey("legacy-screen-code")) return false;
      final actual = params["legacy-screen-code"];
      if (legacyScreenCode is Matcher) {
        if (!legacyScreenCode.matches(actual, {})) return false;
      } else {
        if (actual != legacyScreenCode) return false;
      }
    }
    return true;
  });
}

/// Matcher for screen.view
Matcher isScreenView({
  Object? durationMs,
  Object? previousScreen,
  Object? screenName,
}) {
  return predicate((item) {
    if (item is! Map) return false;
    final Map<String, dynamic> params = Map.from(item);

    if (durationMs != null) {
      if (!params.containsKey("duration_ms")) return false;
      final actual = params["duration_ms"];
      if (durationMs is Matcher) {
        if (!durationMs.matches(actual, {})) return false;
      } else {
        if (actual != durationMs) return false;
      }
    }
    if (previousScreen != null) {
      if (!params.containsKey("previous_screen")) return false;
      final actual = params["previous_screen"];
      if (previousScreen is Matcher) {
        if (!previousScreen.matches(actual, {})) return false;
      } else {
        if (actual != previousScreen) return false;
      }
    }
    if (screenName != null) {
      if (!params.containsKey("screen_name")) return false;
      final actual = params["screen_name"];
      if (screenName is Matcher) {
        if (!screenName.matches(actual, {})) return false;
      } else {
        if (actual != screenName) return false;
      }
    }
    return true;
  });
}
