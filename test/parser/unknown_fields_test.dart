import 'package:analytics_gen/src/parser/event_loader.dart';
import 'package:analytics_gen/src/parser/yaml_parser.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  group('unknown fields', () {
    late List<String> logs;
    late YamlParser parser;

    setUp(() {
      logs = [];
      parser = YamlParser(log: TestLogger(logs));
    });

    Future<void> parseEvents(String content) => parser.parseEvents([
          AnalyticsSource(filePath: 'events/auth.yaml', content: content),
        ]);

    test('warns about an unknown event field at its key', () async {
      await parseEvents(
        'auth:\n'
        '  login:\n'
        '    description: Login\n'
        '    paramters:\n'
        '      method: string\n',
      );

      expect(logs, [
        'events/auth.yaml:4:5: Unknown field "paramters" in event '
            '"auth.login" is ignored.',
      ]);
    });

    test('warns about an unknown parameter field next to its type', () async {
      await parseEvents(
        'auth:\n'
        '  login:\n'
        '    description: Login\n'
        '    parameters:\n'
        '      method:\n'
        '        type: string\n'
        '        allowed_value: [email]\n',
      );

      expect(logs, [
        'events/auth.yaml:7:9: Unknown field "allowed_value" in parameter '
            '"method" is ignored.',
      ]);
    });

    test('accepts the legacy form that names the type as a key', () async {
      await parseEvents(
        'auth:\n'
        '  login:\n'
        '    description: Login\n'
        '    parameters:\n'
        '      method:\n'
        '        string:\n'
        '        description: Sign-in method\n',
      );

      expect(logs, isEmpty);
    });

    test('warns about keys after a legacy type key', () async {
      await parseEvents(
        'auth:\n'
        '  login:\n'
        '    description: Login\n'
        '    parameters:\n'
        '      method:\n'
        '        string:\n'
        '        colour: red\n',
      );

      expect(logs, [
        'events/auth.yaml:7:9: Unknown field "colour" in parameter '
            '"method" is ignored.',
      ]);
    });

    test('warns about an unknown context property field', () async {
      await parser.parseContexts([
        AnalyticsSource(
          filePath: 'contexts/user.yaml',
          content: 'user:\n'
              '  plan:\n'
              '    type: string\n'
              '    operation: [set]\n',
        ),
      ]);

      expect(logs, [
        'contexts/user.yaml:4:5: Unknown field "operation" in parameter '
            '"plan" is ignored.',
      ]);
    });

    test('warns about an unknown root key in a shared parameters file', () {
      parser.parseSharedParameters(
        AnalyticsSource(
          filePath: 'shared.yaml',
          content: 'parameter:\n'
              '  user_id: string\n',
        ),
      );

      expect(logs, [
        'shared.yaml:1:1: Unknown field "parameter" in the shared parameters '
            'file is ignored.',
      ]);
    });

    test('warns about an unknown shared parameter field', () {
      parser.parseSharedParameters(
        AnalyticsSource(
          filePath: 'shared.yaml',
          content: 'parameters:\n'
              '  user_id:\n'
              '    type: string\n'
              '    descripton: Signed-in user\n',
        ),
      );

      expect(logs, [
        'shared.yaml:4:5: Unknown field "descripton" in parameter '
            '"user_id" is ignored.',
      ]);
    });
  });
}
