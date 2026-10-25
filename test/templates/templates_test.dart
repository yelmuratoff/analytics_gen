import 'dart:io';

import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/config/config_parser.dart';
import 'package:analytics_gen/src/config/parser_config.dart';
import 'package:analytics_gen/src/parser/event_loader.dart';
import 'package:analytics_gen/src/parser/yaml_parser.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('templates', () {
    AnalyticsSource template(String name) => AnalyticsSource(
          filePath: 'templates/$name',
          content: File('templates/$name').readAsStringSync(),
        );

    test('the config template loads as an analytics_gen config', () {
      final yaml = loadYaml(template('analytics_gen.yaml').content) as Map;

      final config = const ConfigParser().parse(yaml);

      expect(config.naming.eventNameTemplate, '{domain}: {event}');
    });

    test(
        'the config template, built from schema defaults, matches the Dart '
        'defaults', () {
      final yaml = loadYaml(template('analytics_gen.yaml').content) as Map;

      final parsed = const ConfigParser().parse(yaml);
      const defaults = AnalyticsConfig();

      Map<String, Object?> fieldsOf(AnalyticsConfig c) => {
            'inputs.events': c.inputs.eventsPath,
            'inputs.contexts': c.inputs.contexts,
            'inputs.shared_parameters': c.inputs.sharedParameters,
            'inputs.imports': c.inputs.imports,
            'outputs.dart': c.outputs.dartPath,
            'outputs.docs': c.outputs.docsPath,
            'outputs.exports': c.outputs.exportsPath,
            'outputs.studio': c.outputs.studioPath,
            'targets.csv': c.targets.generateCsv,
            'targets.json': c.targets.generateJson,
            'targets.sql': c.targets.generateSql,
            'targets.docs': c.targets.generateDocs,
            'targets.plan': c.targets.generatePlan,
            'targets.test_matchers': c.targets.generateTestMatchers,
            'targets.studio': c.targets.generateStudio,
            'rules.include_event_description': c.rules.includeEventDescription,
            'rules.strict_event_names': c.rules.strictEventNames,
            'rules.enforce_centrally_defined_parameters':
                c.rules.enforceCentrallyDefinedParameters,
            'rules.prevent_event_parameter_duplicates':
                c.rules.preventEventParameterDuplicates,
            'naming.casing': c.naming.convention,
            'naming.enforce_snake_case_domains':
                c.naming.enforceSnakeCaseDomains,
            'naming.enforce_snake_case_parameters':
                c.naming.enforceSnakeCaseParameters,
            'naming.event_name_template': c.naming.eventNameTemplate,
            'naming.identifier_template': c.naming.identifierTemplate,
            'naming.domain_aliases': c.naming.domainAliases,
            'meta.auto_tracking_creation_date': c.meta.autoTrackingCreationDate,
            'meta.include_meta_in_parameters': c.meta.includeMetaInParameters,
          };

      expect(fieldsOf(parsed), fieldsOf(defaults));
    });

    test('the shared parameters template parses', () {
      final shared = YamlParser()
          .parseSharedParameters(template('shared_parameters.yaml'));

      final appVersion =
          shared.values.singleWhere((p) => p.codeName == 'app_version');
      expect(appVersion.regex, r'^\d+\.\d+\.\d+$');
    });

    test('the events template parses against the shared parameters template',
        () async {
      final shared = YamlParser()
          .parseSharedParameters(template('shared_parameters.yaml'));

      final domains = await YamlParser(
        config: ParserConfig(sharedParameters: shared),
      ).parseEvents([template('events.yaml')]);

      expect(domains, isNotEmpty);
    });

    test('the context template parses', () async {
      final contexts =
          await YamlParser().parseContexts([template('context.yaml')]);

      expect(contexts, isNotEmpty);
    });
  });
}
