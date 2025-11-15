import 'package:analytics_gen/analytics_gen.dart';

import 'generated_events.dart';

/// Main Analytics singleton class.
///
/// Automatically generated with all domain mixins.
/// Initialize once at app startup, then use throughout your app.
///
/// Example:
/// ```dart
/// Analytics.initialize(YourAnalyticsService());
/// Analytics.instance.logAuthLogin(method: "email");
/// ```
final class Analytics extends AnalyticsBase
    with AnalyticsAuth, AnalyticsPurchase, AnalyticsScreen {
  /// Runtime view of the generated tracking plan.
  static const List<AnalyticsDomain> plan = <AnalyticsDomain>[
    const AnalyticsDomain(
      name: 'auth',
      events: const <AnalyticsEvent>[
        const AnalyticsEvent(
          name: 'login',
          description: 'User logs in to the application',
          deprecated: true,
          replacement: 'auth.login_v2',
          parameters: const <AnalyticsParameter>[
            const AnalyticsParameter(
              name: 'method',
              type: 'string',
              isNullable: false,
              description: 'Login method (email, google, apple)',
            ),
          ],
        ),
        const AnalyticsEvent(
          name: 'login_v2',
          description: 'User logs in to the application (v2)',
          deprecated: false,
          parameters: const <AnalyticsParameter>[
            const AnalyticsParameter(
              name: 'method',
              type: 'string',
              isNullable: false,
              description: 'Login method v2 (email, google, apple)',
            ),
          ],
        ),
        const AnalyticsEvent(
          name: 'logout',
          description: 'User logs out',
          deprecated: false,
          parameters: const <AnalyticsParameter>[],
        ),
        const AnalyticsEvent(
          name: 'signup',
          description: 'User creates a new account',
          deprecated: false,
          parameters: const <AnalyticsParameter>[
            const AnalyticsParameter(
              name: 'method',
              type: 'string',
              isNullable: false,
            ),
            const AnalyticsParameter(
              name: 'referral_code',
              type: 'string',
              isNullable: true,
              description: 'Optional referral code used during signup',
            ),
          ],
        ),
      ],
    ),
    const AnalyticsDomain(
      name: 'purchase',
      events: const <AnalyticsEvent>[
        const AnalyticsEvent(
          name: 'cancelled',
          description: 'User cancelled a purchase',
          deprecated: false,
          parameters: const <AnalyticsParameter>[
            const AnalyticsParameter(
              name: 'product_id',
              type: 'string',
              isNullable: false,
            ),
            const AnalyticsParameter(
              name: 'reason',
              type: 'string',
              isNullable: true,
              description: 'Reason for cancellation',
            ),
          ],
        ),
        const AnalyticsEvent(
          name: 'completed',
          description: 'User completed a purchase',
          deprecated: false,
          parameters: const <AnalyticsParameter>[
            const AnalyticsParameter(
              name: 'currency',
              type: 'string',
              isNullable: false,
            ),
            const AnalyticsParameter(
              name: 'price',
              type: 'double',
              isNullable: false,
            ),
            const AnalyticsParameter(
              name: 'product_id',
              type: 'string',
              isNullable: false,
            ),
            const AnalyticsParameter(
              name: 'quantity',
              type: 'int',
              isNullable: false,
              description: 'Number of items purchased',
            ),
          ],
        ),
      ],
    ),
    const AnalyticsDomain(
      name: 'screen',
      events: const <AnalyticsEvent>[
        const AnalyticsEvent(
          name: 'view',
          description: 'User views a screen',
          customEventName: 'Screen: View',
          deprecated: false,
          parameters: const <AnalyticsParameter>[
            const AnalyticsParameter(
              name: 'duration_ms',
              type: 'int',
              isNullable: true,
              description: 'Time spent on previous screen in milliseconds',
            ),
            const AnalyticsParameter(
              name: 'previous_screen',
              type: 'string',
              isNullable: true,
              description: 'Name of the previous screen',
            ),
            const AnalyticsParameter(
              name: 'screen_name',
              type: 'string',
              isNullable: false,
            ),
          ],
        ),
      ],
    ),
  ];

  static final Analytics _instance = Analytics._internal();
  Analytics._internal();

  /// Access the singleton instance
  static Analytics get instance => _instance;

  IAnalytics? _analytics;

  /// Whether analytics has been initialized
  bool get isInitialized => _analytics != null;

  /// Initialize analytics with your provider
  ///
  /// Call this once at app startup before using any analytics methods.
  static void initialize(IAnalytics analytics) {
    _instance._analytics = analytics;
  }

  @override
  IAnalytics get logger => ensureAnalyticsInitialized(_analytics);
}
