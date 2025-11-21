// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import
// ignore_for_file: directives_ordering, unnecessary_string_interpolations
// coverage:ignore-file

import 'package:analytics_gen/analytics_gen.dart';
import 'package:meta/meta.dart';

import 'generated_events.dart';
import 'contexts/theme_context.dart';
import 'contexts/user_properties_context.dart';

/// Main Analytics class.
///
/// Automatically generated with all domain mixins.
/// Supports both Dependency Injection and Singleton usage.
///
/// Usage (DI):
/// ```dart
/// final analytics = Analytics(YourAnalyticsService());
/// analytics.logAuthLogin(method: "email");
/// ```
///
/// Usage (Singleton):
/// ```dart
/// Analytics.initialize(YourAnalyticsService());
/// Analytics.instance.logAuthLogin(method: "email");
/// ```
///
/// ## Available Capabilities
///
/// This class provides context property setters via capabilities:
///
/// **Theme**
/// - Key: `themeKey`
/// - Type: `ThemeCapability`
/// - Usage:
/// ```dart
/// Analytics.instance.setThemePropertyName(value);
/// ```
///
/// **UserProperties**
/// - Key: `userPropertiesKey`
/// - Type: `UserPropertiesCapability`
/// - Usage:
/// ```dart
/// Analytics.instance.setUserPropertiesPropertyName(value);
/// ```
///
/// Note: Capabilities are provider-specific. Ensure your analytics
/// provider implements the required capability interfaces.
final class Analytics extends AnalyticsBase with
    AnalyticsAuth,
    AnalyticsPurchase,
    AnalyticsScreen,
    AnalyticsTheme,
    AnalyticsUserProperties
{
  final IAnalytics _analytics;
  final AnalyticsCapabilityResolver _capabilities;

  /// Constructor for Dependency Injection.
  const Analytics(
    this._analytics, [
    this._capabilities = const NullCapabilityResolver(),
  ]);

  /// Runtime view of the generated tracking plan.
  static const List<AnalyticsDomain> plan = <AnalyticsDomain>[
    AnalyticsDomain(
      name: 'auth',
      events: <AnalyticsEvent>[
        AnalyticsEvent(
          name: 'login',
          description: 'User logs in to the application',
          deprecated: true,
          replacement: 'auth.login_v2',
          meta: <String, Object?>{
            'owner': 'auth-team',
            'tier': 'critical',
          },
          parameters: <AnalyticsParameter>[
            AnalyticsParameter(
              name: 'method',
              type: 'string',
              isNullable: false,
              description: 'Login method (email, google, apple)',
              meta: <String, Object?>{
                'pii': true,
              },
            ),
          ],
        ),
        AnalyticsEvent(
          name: 'login_v2',
          description: 'User logs in to the application (v2)',
          deprecated: false,
          parameters: <AnalyticsParameter>[
            AnalyticsParameter(
              name: 'login-method',
              codeName: 'login_method',
              type: 'string',
              isNullable: false,
              description: 'Login method v2 (email, google, apple)',
              allowedValues: <Object>[
                'email',
                'google',
                'apple',
              ],
            ),
          ],
        ),
        AnalyticsEvent(
          name: 'logout',
          description: 'User logs out',
          deprecated: false,
          parameters: <AnalyticsParameter>[
          ],
        ),
        AnalyticsEvent(
          name: 'phone_login',
          description: 'When user logs in via phone',
          identifier: 'auth.phone_login',
          customEventName: 'Auth: Phone {phone_country}',
          deprecated: false,
          parameters: <AnalyticsParameter>[
            AnalyticsParameter(
              name: 'phone_country',
              type: 'string',
              isNullable: false,
              description: 'ISO country code for the dialed number',
            ),
            AnalyticsParameter(
              name: 'tracking-token',
              codeName: 'tracking_token',
              type: 'string',
              isNullable: false,
              description: 'Legacy token kept for backend reconciliation',
            ),
            AnalyticsParameter(
              name: 'user_exists',
              type: 'bool',
              isNullable: true,
              description: 'Whether the user exists or not',
            ),
          ],
        ),
        AnalyticsEvent(
          name: 'signup',
          description: 'User creates a new account',
          deprecated: false,
          parameters: <AnalyticsParameter>[
            AnalyticsParameter(
              name: 'method',
              type: 'string',
              isNullable: false,
            ),
            AnalyticsParameter(
              name: 'referral_code',
              type: 'string',
              isNullable: true,
              description: 'Optional referral code used during signup',
            ),
          ],
        ),
      ],
    ),
    AnalyticsDomain(
      name: 'purchase',
      events: <AnalyticsEvent>[
        AnalyticsEvent(
          name: 'cancelled',
          description: 'User cancelled a purchase',
          deprecated: false,
          parameters: <AnalyticsParameter>[
            AnalyticsParameter(
              name: 'product_id',
              type: 'string',
              isNullable: false,
            ),
            AnalyticsParameter(
              name: 'reason',
              type: 'string',
              isNullable: true,
              description: 'Reason for cancellation',
            ),
          ],
        ),
        AnalyticsEvent(
          name: 'completed',
          description: 'User completed a purchase',
          deprecated: false,
          parameters: <AnalyticsParameter>[
            AnalyticsParameter(
              name: 'currency-code',
              codeName: 'currency_code',
              type: 'string',
              isNullable: false,
            ),
            AnalyticsParameter(
              name: 'amount_value',
              codeName: 'price',
              type: 'double',
              isNullable: false,
              description: 'Localized amount used by legacy dashboards',
            ),
            AnalyticsParameter(
              name: 'product_id',
              type: 'string',
              isNullable: false,
            ),
            AnalyticsParameter(
              name: 'quantity',
              type: 'int',
              isNullable: false,
              description: 'Number of items purchased',
            ),
          ],
        ),
      ],
    ),
    AnalyticsDomain(
      name: 'screen',
      events: <AnalyticsEvent>[
        AnalyticsEvent(
          name: 'legacy_view',
          description: 'Legacy backend identifier kept for parity',
          identifier: 'screen.legacy_view',
          customEventName: 'Screen: Legacy',
          deprecated: false,
          parameters: <AnalyticsParameter>[
            AnalyticsParameter(
              name: 'legacy-screen-code',
              codeName: 'legacy_screen_code',
              type: 'string',
              isNullable: false,
              description: 'Three-letter code provided by data team',
            ),
          ],
        ),
        AnalyticsEvent(
          name: 'view',
          description: 'User views a screen',
          customEventName: 'Screen: {screen_name}',
          deprecated: false,
          parameters: <AnalyticsParameter>[
            AnalyticsParameter(
              name: 'duration_ms',
              type: 'int',
              isNullable: true,
              description: 'Time spent on previous screen in milliseconds',
            ),
            AnalyticsParameter(
              name: 'previous_screen',
              type: 'string',
              isNullable: true,
              description: 'Name of the previous screen',
            ),
            AnalyticsParameter(
              name: 'screen_name',
              type: 'string',
              isNullable: false,
            ),
          ],
        ),
      ],
    ),
  ];

  static const Map<String, Set<String>> _piiProperties = {
    'auth: login': {'method'},
  };

  /// The fingerprint of the plan used to generate this code.
  static const String planFingerprint = '-793406a6e0411e6f';

  // --- Singleton Compatibility ---

  static Analytics? _instance;

  /// Access the singleton instance
  static Analytics get instance {
    if (_instance == null) {
      throw StateError('Analytics.initialize() must be called before accessing Analytics.instance.\nEnsure you call Analytics.initialize() in your main() function or before using any analytics features.');
    }
    return _instance!;
  }

  /// Whether analytics has been initialized
  static bool get isInitialized => _instance != null;

  /// Initialize analytics with your provider
  ///
  /// Call this once at app startup before using any analytics methods.
  static void initialize(IAnalytics analytics) {
    if (_instance != null) {
      throw StateError('Analytics is already initialized.');
    }
    _instance = Analytics(analytics, analyticsCapabilitiesFor(analytics));
  }

  /// Resets the singleton instance. Useful for testing.
  @visibleForTesting
  static void reset() {
    _instance = null;
  }

  /// Returns a copy of [parameters] with PII values redacted.
  ///
  /// PII properties are defined in YAML with `meta: { pii: true }`.
  /// This method is useful for logging to console or non-secure backends.
  static Map<String, Object?> sanitizeParams(
    String eventName,
    Map<String, Object?>? parameters,
  ) {
    if (parameters == null || parameters.isEmpty) {
      return const {};
    }

    final piiKeys = _piiProperties[eventName];
    if (piiKeys == null) {
      return Map.of(parameters);
    }

    final sanitized = Map.of(parameters);
    for (final key in piiKeys) {
      if (sanitized.containsKey(key)) {
        sanitized[key] = '[REDACTED]';
      }
    }
    return sanitized;
  }

  // --- Implementation ---

  @override
  IAnalytics get logger => _analytics;

  @override
  AnalyticsCapabilityResolver get capabilities => _capabilities;
}

