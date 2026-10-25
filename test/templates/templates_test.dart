import 'dart:io';

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
