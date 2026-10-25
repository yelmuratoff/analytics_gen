import 'dart:convert';
import 'dart:io';

import 'package:analytics_gen/src/core/exceptions.dart';
import 'package:analytics_gen/src/parser/event_loader.dart';
import 'package:analytics_gen/src/parser/yaml_parser.dart';
import 'package:test/test.dart';

void main() {
  group('parameter rules by type', () {
    final parameterSchema = jsonDecode(
      File('schema/parameter.schema.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final properties = parameterSchema['properties'] as Map<String, dynamic>;
    final typeExamples = List<String>.from(
      (properties['type'] as Map<String, dynamic>)['examples'] as List,
    );

    List<String> supportedTypes(String rule) {
      final constraints = (properties[rule]
          as Map<String, dynamic>)['x-constraints'] as Map<String, dynamic>;
      return List<String>.from(constraints['supported_types'] as List);
    }

    Future<void> parseParameter(String type, String rule, Object value) {
      return YamlParser().parseEvents([
        AnalyticsSource(
          filePath: 'events.yaml',
          content: 'app:\n'
              '  opened:\n'
              '    description: Test\n'
              '    parameters:\n'
              '      field:\n'
              '        type: $type\n'
              '        $rule: $value\n',
        ),
      ]);
    }

    const ruleValues = {
      'regex': "'^a'",
      'min_length': 1,
      'max_length': 5,
      'min': 0,
      'max': 10,
    };

    for (final MapEntry(key: rule, value: value) in ruleValues.entries) {
      test('accepts $rule on every type the schema lists for it', () async {
        for (final type in supportedTypes(rule)) {
          await expectLater(
            parseParameter(type, rule, value),
            completes,
            reason: '$rule on $type',
          );
        }
      });

      test('rejects $rule on every other type from the schema examples',
          () async {
        final unsupported = typeExamples
            .where((type) => !supportedTypes(rule).contains(type))
            .toList();
        expect(unsupported, isNotEmpty);

        for (final type in unsupported) {
          await expectLater(
            parseParameter(type, rule, value),
            throwsA(
              isA<AnalyticsAggregateException>()
                  .having(
                    (e) => e.errors.single.message,
                    'message',
                    startsWith('$rule only applies to '),
                  )
                  .having((e) => e.errors.single.span, 'span', isNotNull),
            ),
            reason: '$rule on $type',
          );
        }
      });
    }

    test('accepts length rules on a nullable or capitalized String type',
        () async {
      await expectLater(parseParameter('String?', 'min_length', 1), completes);
      await expectLater(parseParameter('String', 'max_length', 5), completes);
    });

    test('skips the type check when dart_type overrides the generated type',
        () async {
      final domains = await YamlParser().parseEvents([
        AnalyticsSource(
          filePath: 'events.yaml',
          content: 'app:\n'
              '  opened:\n'
              '    description: Test\n'
              '    parameters:\n'
              '      code:\n'
              '        type: string\n'
              '        dart_type: PromoCode\n'
              '        min: 1\n',
        ),
      ]);

      expect(domains['app']!.events.single.parameters.single.min, 1);
    });
  });
}
