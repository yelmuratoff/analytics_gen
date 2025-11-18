import 'package:analytics_gen/analytics_gen.dart';
import 'src/analytics/generated/analytics.dart';

Future<void> main() async {
  // Initialize analytics with a mock service for demonstration
  final mockService = MockAnalyticsService(verbose: true);
  Analytics.initialize(mockService);

  print('analytics_gen example\n');
  print('═' * 50);
  print('\nDemonstrating type-safe analytics event logging:\n');

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
    currencyCode: 'USD',
    quantity: 1,
  );

  // Example 6: Purchase cancelled with nullable reason
  print('\n6. Logging purchase cancellation');
  Analytics.instance.logPurchaseCancelled(
    productId: 'premium_yearly',
    reason: 'Too expensive',
  );

  // Example 7: Async logging when a caller prefers awaiting delivery
  print('\n7. Logging via AsyncAnalyticsAdapter (awaited)');
  final asyncAdapter = AsyncAnalyticsAdapter(mockService);
  await asyncAdapter.logEventAsync(
    name: 'example_async_event',
    parameters: {'flow': 'awaited'},
  );
  print('   Async logEventAsync call completed.');

  // Display summary
  print('\n${'═' * 50}');
  print('\nSummary:');
  print('Total events logged: ${mockService.totalEvents}');
  print('\nAll logged events:');

  for (var i = 0; i < mockService.records.length; i++) {
    final record = mockService.records[i];
    print('\n${i + 1}. ${record.name}');
    if (record.parameters.isNotEmpty) {
      print('   Parameters:');
      record.parameters.forEach((key, value) {
        print('   - $key: $value');
      });
    }
  }

  print('\n${'═' * 50}');
  print('\nTo generate code for your own tracking plan:');
  print('1. Define events in YAML files under the events/ directory');
  print('2. Run: dart run analytics_gen:generate --docs --exports');
  print('3. Use the generated, type-safe methods in your code');
  print('\n${'═' * 50}');
}
