import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../src/analytics/generated/analytics.dart';
import 'analytics_event_log.dart';

/// View-model that exposes domain actions (purchase, onboarding, etc.) and an event log.
class HomeScreenController extends ChangeNotifier {
  final List<LoggedAnalyticsEvent> _events = <LoggedAnalyticsEvent>[];

  UnmodifiableListView<LoggedAnalyticsEvent> get events =>
      UnmodifiableListView(_events);

  void recordEvent(LoggedAnalyticsEvent event) {
    _events.insert(0, event);
    notifyListeners();
  }

  /// Simulates a customer buying a monthly subscription.
  void purchaseMonthlySubscription() {
    Analytics.instance.logPurchaseCompleted(
      productId: 'premium_monthly',
      price: 9.99,
      currencyCode: 'USD',
      quantity: 1,
    );
  }

  /// Captures a user signing up via an invite link.
  void completeInviteSignup() {
    Analytics.instance.logAuthSignup(
      method: 'invite_link',
      referralCode: 'INVITE2025',
    );
  }

  /// Indicates that the user landed on the home dashboard after auth.
  void showHomeDashboard() {
    Analytics.instance.logScreenView(
      screenName: 'home_dashboard',
      previousScreen: 'login',
      durationMs: 5200,
    );
  }

  /// Tracks a returning user logging in with biometrics.
  void authenticateReturningUser() {
    Analytics.instance.logAuthLogin(method: 'biometrics');
  }

  /// Sets theme context properties.
  void toggleTheme() {
    Analytics.instance.setThemeIsDarkMode(true);
    Analytics.instance.setThemePrimaryColor('#FF0000');
  }

  /// Sets user properties.
  void setUserProperties() {
    Analytics.instance.setUserPropertiesUserId('user_123');
    Analytics.instance.setUserPropertiesUserRole('admin');
    Analytics.instance.setUserPropertiesIsPremium(true);
  }

  void clearLog() {
    if (_events.isEmpty) return;
    _events.clear();
    notifyListeners();
  }
}
