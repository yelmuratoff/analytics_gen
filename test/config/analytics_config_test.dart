import 'package:analytics_gen/src/config/config_parser.dart';
import 'package:test/test.dart';

void main() {
  group('ConfigParser.parse', () {
    test('returns defaults when analytics_gen section is missing', () {
      final config = ConfigParser().parse({});

      expect(config.eventsPath, 'events');
      expect(config.outputPath, 'src/analytics/generated');
      expect(config.docsPath, isNull);
      expect(config.exportsPath, isNull);
      expect(config.generateCsv, isFalse);
      expect(config.generateJson, isFalse);
      expect(config.generateSql, isFalse);
      expect(config.generateDocs, isFalse);
      expect(config.generatePlan, isTrue);
      expect(config.naming.enforceSnakeCaseDomains, isTrue);
      expect(config.naming.enforceSnakeCaseParameters, isTrue);
      expect(config.naming.eventNameTemplate, '{domain}: {event}');
      expect(config.sharedParameters, isEmpty);
      expect(config.contexts, isEmpty);
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
          'naming': {
            'enforce_snake_case_domains': false,
            'enforce_snake_case_parameters': false,
            'event_name_template': '{domain_alias}.{event}',
            'identifier_template': '{domain}.{event}',
            'domain_aliases': {
              'auth': 'AuthDomain',
            },
          },
        },
      };

      final config = ConfigParser().parse(yaml);

      expect(config.eventsPath, 'custom_events');
      expect(config.outputPath, 'custom_output');
      expect(config.docsPath, 'doc/output');
      expect(config.exportsPath, 'export/output');
      expect(config.generateCsv, isTrue);
      expect(config.generateJson, isTrue);
      expect(config.generateSql, isTrue);
      expect(config.generateDocs, isTrue);
      expect(config.generatePlan, isFalse);
      expect(config.naming.enforceSnakeCaseDomains, isFalse);
      expect(config.naming.enforceSnakeCaseParameters, isFalse);
      expect(config.naming.eventNameTemplate, '{domain_alias}.{event}');
      expect(config.naming.identifierTemplate, '{domain}.{event}');
      expect(config.naming.domainAliases['auth'], 'AuthDomain');
    });

    test('parses sharedParameters from inputs and config override', () {
      final yaml = {
        'analytics_gen': {
          'inputs': {
            'shared_parameters': [
              'shared/one.yaml',
              'shared/two.yaml',
            ],
            'contexts': [
              'shared/user.yaml',
            ],
          },
        },
      };

      final config = ConfigParser().parse(yaml);

      expect(config.sharedParameters, ['shared/one.yaml', 'shared/two.yaml']);
      expect(config.contexts, ['shared/user.yaml']);
    });

    test(
        'falls back to top-level config values for sharedParameters and contexts',
        () {
      final yaml = {
        'analytics_gen': {
          'shared_parameters': [
            'shared/config_level.yaml',
          ],
          'contexts': [
            'shared/config_context.yaml',
          ],
        },
      };

      final config = ConfigParser().parse(yaml);

      expect(config.sharedParameters, ['shared/config_level.yaml']);
      expect(config.contexts, ['shared/config_context.yaml']);
    });

    test(
        'inputs override config-level values for sharedParameters and contexts',
        () {
      final yaml = {
        'analytics_gen': {
          'shared_parameters': [
            'shared/config_level.yaml',
          ],
          'contexts': [
            'shared/config_context.yaml',
          ],
          'inputs': {
            'shared_parameters': [
              'shared/from_inputs.yaml',
            ],
            'contexts': [
              'shared/from_inputs_context.yaml',
            ],
          },
        },
      };

      final config = ConfigParser().parse(yaml);

      expect(config.sharedParameters, ['shared/from_inputs.yaml']);
      expect(config.contexts, ['shared/from_inputs_context.yaml']);
    });
  });
}
