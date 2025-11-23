import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/generator/renderers/test_renderer.dart';
import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';
import 'package:test/test.dart';

void main() {
  group('TestRenderer', () {
    test('renders test file with Dart imports by default', () {
      final config = AnalyticsConfig(
        outputPath: 'src/analytics/generated',
      );
      final renderer = TestRenderer(config);

      final domains = {
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [],
        ),
      };

      final output = renderer.render(domains);

      expect(output, contains("import 'package:test/test.dart';"));
      expect(output,
          isNot(contains("import 'package:flutter_test/flutter_test.dart';")));
    });

    test('renders test file with Flutter imports when isFlutter is true', () {
      final config = AnalyticsConfig(
        outputPath: 'src/analytics/generated',
      );
      final renderer = TestRenderer(config, isFlutter: true);

      final domains = {
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [],
        ),
      };

      final output = renderer.render(domains);

      expect(
          output, contains("import 'package:flutter_test/flutter_test.dart';"));
      expect(output, isNot(contains("import 'package:test/test.dart';")));
    });

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

    test('renders test with parameter having allowed values', () {
      final config = AnalyticsConfig(
        outputPath: 'src/analytics/generated',
      );
      final renderer = TestRenderer(config);

      final domains = {
        'ui': AnalyticsDomain(
          name: 'ui',
          events: [
            AnalyticsEvent(
              name: 'select',
              description: 'Select option',
              parameters: [
                AnalyticsParameter(
                  name: 'option',
                  type: 'string',
                  isNullable: false,
                  allowedValues: ['option1', 'option2'],
                ),
                AnalyticsParameter(
                  name: 'count',
                  type: 'int',
                  isNullable: false,
                  allowedValues: [1, 2, 3],
                ),
              ],
            ),
          ],
        ),
      };

      final output = renderer.render(domains);

      expect(output, contains('option: AnalyticsUiSelectOptionEnum.option1,'));
      expect(output, contains('count: 1,'));
    });

    test('renders test with various parameter types', () {
      final config = AnalyticsConfig(
        outputPath: 'src/analytics/generated',
      );
      final renderer = TestRenderer(config);

      final domains = {
        'data': AnalyticsDomain(
          name: 'data',
          events: [
            AnalyticsEvent(
              name: 'process',
              description: 'Process data',
              parameters: [
                AnalyticsParameter(
                  name: 'value',
                  type: 'double',
                  isNullable: false,
                ),
                AnalyticsParameter(
                  name: 'enabled',
                  type: 'bool',
                  isNullable: false,
                ),
                AnalyticsParameter(
                  name: 'items',
                  type: 'list',
                  isNullable: false,
                ),
              ],
            ),
          ],
        ),
      };

      final output = renderer.render(domains);

      expect(output, contains('value: 42.0,'));
      expect(output, contains('enabled: true,'));
      expect(output, contains('items: const [],'));
    });

    test('renders test with string parameter constraints', () {
      final config = AnalyticsConfig(
        outputPath: 'src/analytics/generated',
      );
      final renderer = TestRenderer(config);

      final domains = {
        'validation': AnalyticsDomain(
          name: 'validation',
          events: [
            AnalyticsEvent(
              name: 'input',
              description: 'User input',
              parameters: [
                AnalyticsParameter(
                  name: 'text',
                  type: 'string',
                  isNullable: false,
                  minLength: 10,
                  maxLength: 20,
                ),
              ],
            ),
          ],
        ),
      };

      final output = renderer.render(domains);

      expect(output, contains("text: 'testtesttest',"));
    });

    test('renders test with string parameter maxLength truncation', () {
      final config = AnalyticsConfig(
        outputPath: 'src/analytics/generated',
      );
      final renderer = TestRenderer(config);

      final domains = {
        'validation': AnalyticsDomain(
          name: 'validation',
          events: [
            AnalyticsEvent(
              name: 'input',
              description: 'User input',
              parameters: [
                AnalyticsParameter(
                  name: 'text',
                  type: 'string',
                  isNullable: false,
                  minLength: 50, // This will make value long
                  maxLength: 10, // This will truncate it
                ),
              ],
            ),
          ],
        ),
      };

      final output = renderer.render(domains);

      expect(output, contains("text: 'testtestte',")); // 10 characters
    });

    test('renders test with double parameter constraints', () {
      final config = AnalyticsConfig(
        outputPath: 'src/analytics/generated',
      );
      final renderer = TestRenderer(config);

      final domains = {
        'math': AnalyticsDomain(
          name: 'math',
          events: [
            AnalyticsEvent(
              name: 'calculate',
              description: 'Calculate value',
              parameters: [
                AnalyticsParameter(
                  name: 'min_val',
                  type: 'double',
                  isNullable: false,
                  min: 10.5,
                ),
                AnalyticsParameter(
                  name: 'max_val',
                  type: 'double',
                  isNullable: false,
                  max: 100.0,
                ),
              ],
            ),
          ],
        ),
      };

      final output = renderer.render(domains);

      expect(output, contains('minVal: 10.5,'));
      expect(output, contains('maxVal: 100.0,'));
    });
  });
}
