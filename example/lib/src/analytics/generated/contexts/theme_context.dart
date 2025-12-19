// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, deprecated_member_use_from_same_package

import 'package:analytics_gen/analytics_gen.dart';

/// Capability interface for Theme
abstract interface class ThemeCapability implements AnalyticsCapability {
  void setThemeProperty(String name, Object? value);
}

/// Key for Theme capability
const themeKey = CapabilityKey<ThemeCapability>('theme');

/// Mixin for Analytics class
mixin AnalyticsTheme on AnalyticsBase {
  /// Whether the app is in dark mode
  void setThemeIsDarkMode(bool value) {
    capability(themeKey)?.setThemeProperty('is_dark_mode', value);
  }

  /// The primary color hex code
  void setThemePrimaryColor(String value) {
    const allowedPrimaryColorValues = <String>{'#FF0000', '#00FF00', '#0000FF'};
    if (!allowedPrimaryColorValues.contains(value)) {
      throw ArgumentError.value(
        value,
        'value',
        'must be one of #FF0000, #00FF00, #0000FF',
      );
    }
    capability(themeKey)?.setThemeProperty('primary_color', value);
  }
}
