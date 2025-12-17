import 'package:analytics_gen/src/config/config_parser.dart';
import 'package:test/test.dart';

void main() {
  group('ConfigParser.parse', () {
    test('returns defaults when analytics_gen section is missing', () {
      final config = ConfigParser().parse({});

      expect(config.inputs.eventsPath, 'events');
      expect(config.outputs.dartPath, 'src/analytics/generated');
      expect(config.outputs.docsPath, isNull);
      expect(config.outputs.exportsPath, isNull);
      expect(config.targets.generateCsv, isFalse);
      expect(config.targets.generateJson, isFalse);
      expect(config.targets.generateSql, isFalse);
      expect(config.targets.generateDocs, isFalse);
      expect(config.targets.generatePlan, isTrue);
      expect(config.naming.enforceSnakeCaseDomains, isTrue);
      expect(config.naming.enforceSnakeCaseParameters, isTrue);
      expect(config.naming.eventNameTemplate, '{domain}: {event}');
      expect(config.inputs.sharedParameters, isEmpty);
      expect(config.inputs.contexts, isEmpty);
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

      expect(config.inputs.eventsPath, 'custom_events');
      expect(config.outputs.dartPath, 'custom_output');
      expect(config.outputs.docsPath, 'doc/output');
      expect(config.outputs.exportsPath, 'export/output');
      expect(config.targets.generateCsv, isTrue);
      expect(config.targets.generateJson, isTrue);
      expect(config.targets.generateSql, isTrue);
      expect(config.targets.generateDocs, isTrue);
      expect(config.targets.generatePlan, isFalse);
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

      expect(config.inputs.sharedParameters,
          ['shared/one.yaml', 'shared/two.yaml']);
      expect(config.inputs.contexts, ['shared/user.yaml']);
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

      expect(config.inputs.sharedParameters, ['shared/config_level.yaml']);
      expect(config.inputs.contexts, ['shared/config_context.yaml']);
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

      expect(config.inputs.sharedParameters, ['shared/from_inputs.yaml']);
      expect(config.inputs.contexts, ['shared/from_inputs_context.yaml']);
    });
  });
}
