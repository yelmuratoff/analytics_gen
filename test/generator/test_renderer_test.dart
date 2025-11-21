import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/generator/renderers/test_renderer.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:test/test.dart';

void main() {
  group('TestRenderer', () {
    test('renders test file with event construction checks', () {
      final config = AnalyticsConfig(
        outputPath: 'src/analytics/generated',
      );
      final renderer = TestRenderer(config);

      final domains = {
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [
            AnalyticsEvent(
              name: 'login',
              description: 'User logs in',
              parameters: [
                AnalyticsParameter(
                  name: 'method',
                  type: 'string',
                  isNullable: false,
                ),
                AnalyticsParameter(
                  name: 'count',
                  type: 'int',
                  isNullable: false,
                ),
              ],
            ),
          ],
        ),
      };

      final output = renderer.render(domains);

      expect(output, contains("import 'package:test/test.dart';"));
      expect(output,
          contains("import '../lib/src/analytics/generated/analytics.dart';"));
      expect(output, contains("group('auth', () {"));
      expect(
          output, contains("test('logAuthLogin constructs correctly', () {"));
      expect(output, contains('expect(() => analytics.logAuthLogin('));
      expect(output, contains("method: 'test',"));
      expect(output, contains('count: 42,'));
      expect(output, contains('), returnsNormally);'));
    });
  });
}
