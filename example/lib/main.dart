import 'package:analytics_gen/analytics_gen.dart';
import 'src/analytics/generated/analytics.dart';

void main() {
  // Initialize analytics with mock service for demonstration
  final mockService = MockAnalyticsService(verbose: true);
  Analytics.initialize(mockService);

  print('Analytics Gen Example\n');
  print('═' * 50);
  print('\nDemonstrating analytics event logging:\n');

  // Example 1: Simple event without parameters
  print('1. Logging logout event (no parameters)');
  Analytics.instance.logAuthLogout();

  // Example 2: Event with required parameters
  print('\n2. Logging login event with method parameter');
  Analytics.instance.logAuthLogin(method: 'email');

  // Example 3: Event with optional parameters
  print('\n3. Logging signup with optional referral code');
  Analytics.instance.logAuthSignup(
    method: 'google',
    referralCode: 'FRIEND2024',
  );

  // Example 4: Screen view event
  print('\n4. Logging screen view');
  Analytics.instance.logScreenView(
    screenName: 'home',
    previousScreen: 'login',
    durationMs: 5000,
  );

  // Example 5: Purchase completed
  print('\n5. Logging purchase completion');
  Analytics.instance.logPurchaseCompleted(
    productId: 'premium_monthly',
    price: 9.99,
    currency: 'USD',
    quantity: 1,
  );

  // Example 6: Purchase cancelled with nullable reason
  print('\n6. Logging purchase cancellation');
  Analytics.instance.logPurchaseCancelled(
    productId: 'premium_yearly',
    reason: 'Too expensive',
  );

  // Display summary
  print('\n${'═' * 50}');
  print('\nSummary:');
  print('Total events logged: ${mockService.totalEvents}');
  print('\nAll logged events:');

  for (var i = 0; i < mockService.events.length; i++) {
    final event = mockService.events[i];
    print('\n${i + 1}. ${event['name']}');
    final params = event['parameters'] as Map<String, dynamic>;
    if (params.isNotEmpty) {
      print('   Parameters:');
      params.forEach((key, value) {
        print('   - $key: $value');
      });
    }
  }

  print('\n${'═' * 50}');
  print('\nTo generate code for your own events:');
  print('1. Create YAML files in the events/ directory');
  print('2. Run: dart run analytics_gen:generate');
  print('3. Use the generated methods in your code!');
  print('\n${'═' * 50}');
}
