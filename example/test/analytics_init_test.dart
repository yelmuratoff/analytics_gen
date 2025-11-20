import 'package:analytics_gen/analytics_gen.dart';
import 'package:analytics_gen_example/src/analytics/generated/analytics.dart';
import 'package:test/test.dart';

void main() {
  test('Analytics.initialize throws if called twice', () {
    final mockService = MockAnalyticsService();

    // Ensure we start fresh (if possible, though static state persists)
    // If this test runs in isolation, _instance is null.
    // If it runs after other tests in the same process, it might be non-null.

    if (!Analytics.isInitialized) {
      Analytics.initialize(mockService);
    }

    // Second call MUST throw
    expect(() => Analytics.initialize(mockService), throwsStateError);
  });
}
