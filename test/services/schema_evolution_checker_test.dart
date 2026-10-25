import 'dart:convert';
import 'dart:io';

import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';
import 'package:analytics_gen/src/models/serialization.dart';
import 'package:analytics_gen/src/services/schema_evolution_checker.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  group('SchemaEvolutionChecker', () {
    late Directory project;
    late List<String> logs;
    late SchemaEvolutionChecker checker;

    setUp(() {
      project = Directory.systemTemp.createTempSync('schema_evolution_');
      logs = [];
      checker = SchemaEvolutionChecker(
        projectRoot: project.path,
        logger: TestLogger(logs),
      );
    });

    tearDown(() => project.deleteSync(recursive: true));

    Map<String, AnalyticsDomain> plan(List<AnalyticsParameter> parameters) => {
          'auth': AnalyticsDomain(name: 'auth', events: [
            AnalyticsEvent(
              name: 'login',
              description: 'Login',
              parameters: parameters,
            ),
          ]),
        };

    void writePreviousExport(Map<String, AnalyticsDomain> domains) {
      File(p.join(project.path, 'exports/analytics_events.json'))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(jsonEncode({
          'domains': [
            for (final domain in domains.values)
              AnalyticsSerialization.domainToMap(domain),
          ],
        }));
    }

    const method =
        AnalyticsParameter(name: 'method', type: 'string', isNullable: false);
    const source =
        AnalyticsParameter(name: 'source', type: 'string', isNullable: true);

    test('does nothing without an exports path', () async {
      await checker.checkSchemaEvolution(plan([method]), null);

      expect(logs, isEmpty);
    });

    test('skips the check when no previous export exists', () async {
      await checker.checkSchemaEvolution(plan([method]), 'exports');

      expect(logs.single, startsWith('No previous schema found at'));
    });

    test('reports no changes for an identical plan', () async {
      writePreviousExport(plan([method]));

      await checker.checkSchemaEvolution(plan([method]), 'exports');

      expect(logs, ['No schema changes detected.']);
    });

    test('lists breaking and non-breaking changes separately', () async {
      writePreviousExport(plan([method]));

      await checker.checkSchemaEvolution(plan([source]), 'exports');

      expect(logs, [
        'Detected 1 schema changes:',
        contains('Parameter "source" was added.'),
        'Detected 1 BREAKING schema changes:',
        contains('Parameter "method" was removed.'),
      ]);
    });

    test('warns instead of failing when the previous export is unreadable',
        () async {
      File(p.join(project.path, 'exports/analytics_events.json'))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('{not json');

      await checker.checkSchemaEvolution(plan([method]), 'exports');

      expect(logs.single, startsWith('Failed to check schema evolution:'));
    });
  });
}
