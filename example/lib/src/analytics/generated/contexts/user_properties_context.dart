// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:analytics_gen/analytics_gen.dart';

/// Capability interface for UserProperties
abstract class UserPropertiesCapability implements AnalyticsCapability {
  void setUserPropertiesProperty(String name, Object? value);
}

/// Key for UserProperties capability
const userPropertiesKey = CapabilityKey<UserPropertiesCapability>(
  'user_properties',
);

/// Mixin for Analytics class
mixin AnalyticsUserProperties on AnalyticsBase {
  /// Whether the user has a premium subscription
  void setUserPropertiesIsPremium(bool value) {
    capability(
      userPropertiesKey,
    )?.setUserPropertiesProperty('is_premium', value);
  }

  /// Unique identifier for the user
  void setUserPropertiesUserId(String value) {
    capability(userPropertiesKey)?.setUserPropertiesProperty('user_id', value);
  }

  /// Role of the user in the system
  void setUserPropertiesUserRole(String value) {
    const allowedUserRoleValues = <String>{'admin', 'editor', 'viewer'};
    if (!allowedUserRoleValues.contains(value)) {
      throw ArgumentError.value(
        value,
        'value',
        'must be one of admin, editor, viewer',
      );
    }
    capability(
      userPropertiesKey,
    )?.setUserPropertiesProperty('user_role', value);
  }
}
