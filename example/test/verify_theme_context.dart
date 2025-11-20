import 'package:analytics_gen/analytics_gen.dart';
import 'package:analytics_gen_example/src/analytics/generated/analytics.dart';
import 'package:test/test.dart';

void main() {
  test('Verify Theme Context Generation', () {
    final mockService = MockAnalyticsService(verbose: true);
    Analytics.initialize(mockService);

    // Verify the method exists and runs
    Analytics.instance.setThemeIsDarkMode(true);
    Analytics.instance.setThemePrimaryColor('#FF0000');

    // Verify validation logic
    expect(
      () => Analytics.instance.setThemePrimaryColor('#INVALID'),
      throwsArgumentError,
    );
  });
}
