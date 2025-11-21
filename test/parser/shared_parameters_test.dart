import 'package:analytics_gen/src/core/exceptions.dart';
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

      final eventParser = YamlParser(sharedParameters: shared);
      final domains = await eventParser.parseEvents([eventSource]);

      final event = domains['events']!.events.first;
      expect(event.parameters, hasLength(2));

      final flowId = event.parameters.firstWhere((p) => p.name == 'flow_id');
      expect(flowId.type, 'String');
      expect(flowId.description, 'Shared flow ID');
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
        sharedParameters: shared,
        enforceCentrallyDefinedParameters: true,
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
        sharedParameters: shared,
        preventEventParameterDuplicates: true,
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
  });
}
