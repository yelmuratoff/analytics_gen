import 'package:analytics_gen/analytics_gen.dart';
import 'package:analytics_gen_example/src/analytics/generated/analytics.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {
    // Ensure clean state before each test
    if (Analytics.isInitialized) {
      Analytics.reset();
    }
  });

  tearDown(() {
    // Clean up after tests
    if (Analytics.isInitialized) {
      Analytics.reset();
    }
  });

  test('Analytics.initialize throws if called twice', () {
    final mockService = MockAnalyticsService();

    Analytics.initialize(mockService);
    expect(Analytics.isInitialized, isTrue);

    // Second call MUST throw
    expect(() => Analytics.initialize(mockService), throwsStateError);
  });

  test('Analytics.reset clears the instance', () {
    final mockService = MockAnalyticsService();

    Analytics.initialize(mockService);
    expect(Analytics.isInitialized, isTrue);

    Analytics.reset();
    expect(Analytics.isInitialized, isFalse);

    // Should be able to initialize again
    Analytics.initialize(mockService);
    expect(Analytics.isInitialized, isTrue);
  });
}
