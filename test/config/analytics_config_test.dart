import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:test/test.dart';

void main() {
  group('AnalyticsConfig.fromYaml', () {
    test('returns defaults when analytics_gen section is missing', () {
      final config = AnalyticsConfig.fromYaml({});

      expect(config.eventsPath, 'events');
      expect(config.outputPath, 'src/analytics/generated');
      expect(config.docsPath, isNull);
      expect(config.exportsPath, isNull);
      expect(config.generateCsv, isFalse);
      expect(config.generateJson, isFalse);
      expect(config.generateSql, isFalse);
      expect(config.generateDocs, isFalse);
      expect(config.generatePlan, isTrue);
    });

    test('applies overrides when analytics_gen section exists', () {
      final yaml = {
        'analytics_gen': {
          'events_path': 'custom_events',
          'output_path': 'custom_output',
          'docs_path': 'doc/output',
          'exports_path': 'export/output',
          'generate_csv': true,
          'generate_json': true,
          'generate_sql': true,
          'generate_docs': true,
          'generate_plan': false,
        },
      };

      final config = AnalyticsConfig.fromYaml(yaml);

      expect(config.eventsPath, 'custom_events');
      expect(config.outputPath, 'custom_output');
      expect(config.docsPath, 'doc/output');
      expect(config.exportsPath, 'export/output');
      expect(config.generateCsv, isTrue);
      expect(config.generateJson, isTrue);
      expect(config.generateSql, isTrue);
      expect(config.generateDocs, isTrue);
      expect(config.generatePlan, isFalse);
    });
  });
}
