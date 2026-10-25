import 'package:analytics_gen/src/config/parser_config.dart';
import 'package:analytics_gen/src/core/exceptions.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';
import 'package:analytics_gen/src/parser/event_loader.dart';
import 'package:analytics_gen/src/parser/yaml_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Shared Parameters', () {
    test('parses shared parameters correctly', () {
      final source = AnalyticsSource(
        filePath: 'shared.yaml',
        content: '''
parameters:
  flow_id:
    type: String
    description: Shared flow ID
  user_id:
    type: int
''',
      );

      final parser = YamlParser();
      final shared = parser.parseSharedParameters(source);

      expect(shared, hasLength(2));
      expect(shared['flow_id']?.type, 'String');
      expect(shared['flow_id']?.description, 'Shared flow ID');
      expect(shared['user_id']?.type, 'int');
    });

    test('resolves shared parameters in events', () async {
      final sharedSource = AnalyticsSource(
        filePath: 'shared.yaml',
        content: '''
parameters:
  flow_id:
    type: String
    description: Shared flow ID
''',
      );

      final parser = YamlParser();
      final shared = parser.parseSharedParameters(sharedSource);

      final eventSource = AnalyticsSource(
        filePath: 'events.yaml',
        content: '''
events:
  my_event:
    description: My Event
    parameters:
      flow_id: # null, should resolve to shared
      local_param:
        type: bool
''',
      );

      final eventParser =
          YamlParser(config: ParserConfig(sharedParameters: shared));
      final domains = await eventParser.parseEvents([eventSource]);

      final event = domains['events']!.events.first;
      expect(event.parameters, hasLength(2));

      final flowId = event.parameters.firstWhere((p) => p.name == 'flow_id');
      expect(flowId.type, 'String');
      expect(flowId.description, 'Shared flow ID');
    });

    group('a shared parameter with param_name', () {
      final shared = YamlParser().parseSharedParameters(
        AnalyticsSource(
          filePath: 'shared.yaml',
          content: 'parameters:\n'
              '  app_version:\n'
              '    type: string\n'
              '    param_name: app_ver\n',
        ),
      );

      Future<AnalyticsParameter> resolve(String reference) async {
        final domains = await YamlParser(
          config: ParserConfig(
            sharedParameters: shared,
            enforceCentrallyDefinedParameters: true,
          ),
        ).parseEvents([
          AnalyticsSource(
            filePath: 'events.yaml',
            content: 'app:\n'
                '  opened:\n'
                '    description: Opened\n'
                '    parameters:\n'
                '      $reference:\n',
          ),
        ]);
        return domains['app']!.events.single.parameters.single;
      }

      test('resolves by its key in the shared file', () async {
        final parameter = await resolve('app_version');

        expect(parameter.name, 'app_ver');
        expect(parameter.codeName, 'app_version');
      });

      test('still resolves by its wire name', () async {
        final parameter = await resolve('app_ver');

        expect(parameter.name, 'app_ver');
      });
    });

    test('enforces centrally defined parameters', () async {
      final sharedSource = AnalyticsSource(
        filePath: 'shared.yaml',
        content: '''
parameters:
  flow_id:
    type: String
''',
      );

      final parser = YamlParser();
      final shared = parser.parseSharedParameters(sharedSource);

      final eventSource = AnalyticsSource(
        filePath: 'events.yaml',
        content: '''
events:
  my_event:
    description: My Event
    parameters:
      local_param: # Not in shared
        type: bool
''',
      );

      final eventParser = YamlParser(
        config: ParserConfig(
          sharedParameters: shared,
          enforceCentrallyDefinedParameters: true,
        ),
      );

      expect(
        () => eventParser.parseEvents([eventSource]),
        throwsA(isA<AnalyticsAggregateException>().having(
          (e) => e.errors.first.message,
          'message',
          contains('must be centrally defined'),
        )),
      );
    });

    test('prevents duplicates when configured', () async {
      final sharedSource = AnalyticsSource(
        filePath: 'shared.yaml',
        content: '''
parameters:
  flow_id:
    type: String
''',
      );

      final parser = YamlParser();
      final shared = parser.parseSharedParameters(sharedSource);

      final eventSource = AnalyticsSource(
        filePath: 'events.yaml',
        content: '''
events:
  my_event:
    description: My Event
    parameters:
      flow_id: # Redefined
        type: String
''',
      );

      final eventParser = YamlParser(
        config: ParserConfig(
          sharedParameters: shared,
          preventEventParameterDuplicates: true,
        ),
      );

      expect(
        () => eventParser.parseEvents([eventSource]),
        throwsA(isA<AnalyticsAggregateException>().having(
          (e) => e.errors.first.message,
          'message',
          contains('already defined in the shared parameters'),
        )),
      );
    });

    test('throws AnalyticsParseException when YAML parsing fails', () {
      final source = AnalyticsSource(
        filePath: 'shared.yaml',
        content: 'some content',
      );

      // Inject a loadYaml function that always throws to verify error handling
      final parser = YamlParser(
        loadYaml: (content, {sourceUrl, recover, errorListener}) {
          throw FormatException('Mock parsing error');
        },
      );

      expect(
        () => parser.parseSharedParameters(source),
        throwsA(isA<AnalyticsParseException>().having(
          (e) => e.message,
          'message',
          'Invalid YAML: Mock parsing error',
        )),
      );
    });

    test('returns empty map when shared parameters file is empty', () {
      final source = AnalyticsSource(
        filePath: 'shared.yaml',
        content: '',
      );

      final parser = YamlParser();
      final shared = parser.parseSharedParameters(source);

      expect(shared, isEmpty);
    });

    test(
        'throws AnalyticsParseException when shared parameters file is not a map',
        () {
      final source = AnalyticsSource(
        filePath: 'shared.yaml',
        content: '- list item',
      );

      final parser = YamlParser();

      expect(
        () => parser.parseSharedParameters(source),
        throwsA(isA<AnalyticsParseException>().having(
          (e) => e.message,
          'message',
          contains('Shared parameters file must be a map'),
        )),
      );
    });

    test('returns empty map when parameters key is missing', () {
      final source = AnalyticsSource(
        filePath: 'shared.yaml',
        content: 'other_config: value',
      );

      final parser = YamlParser();
      final shared = parser.parseSharedParameters(source);

      expect(shared, isEmpty);
    });

    test('throws AnalyticsParseException when parameters key is not a map', () {
      final source = AnalyticsSource(
        filePath: 'shared.yaml',
        content: '''
parameters:
  - list item
''',
      );

      final parser = YamlParser();

      expect(
        () => parser.parseSharedParameters(source),
        throwsA(isA<AnalyticsParseException>().having(
          (e) => e.message,
          'message',
          contains('The "parameters" key must be a map'),
        )),
      );
    });
  });
}
