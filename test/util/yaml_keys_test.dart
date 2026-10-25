import 'dart:convert';
import 'dart:io';

import 'package:analytics_gen/src/util/yaml_keys.dart';
import 'package:test/test.dart';

void main() {
  group('YamlKeys field sets', () {
    Map<String, dynamic> schema(String name) =>
        jsonDecode(File('schema/$name').readAsStringSync())
            as Map<String, dynamic>;

    Set<String> propertyNames(Map<String, dynamic> objectSchema) =>
        (objectSchema['properties'] as Map<String, dynamic>).keys.toSet();

    test('eventFields matches the event schema', () {
      final defs = schema('events.schema.json')[r'$defs'] as Map;

      expect(
        YamlKeys.eventFields,
        propertyNames(defs['event'] as Map<String, dynamic>),
      );
    });

    test('parameterFields matches the parameter schema', () {
      expect(
        YamlKeys.parameterFields,
        propertyNames(schema('parameter.schema.json')),
      );
    });

    test('sharedParametersFileFields matches the shared parameters schema', () {
      expect(
        YamlKeys.sharedParametersFileFields,
        propertyNames(schema('shared_parameters.schema.json')),
      );
    });
  });
}
