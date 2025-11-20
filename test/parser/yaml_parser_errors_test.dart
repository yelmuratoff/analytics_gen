import 'dart:io';

import 'package:analytics_gen/src/core/exceptions.dart';
import 'package:analytics_gen/src/parser/yaml_parser.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('YamlParser Error Aggregation', () {
    late Directory tempDir;
    late String eventsPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('analytics_gen_errors_');
      eventsPath = tempDir.path;
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('collects multiple errors from a single file', () async {
      final yamlFile = File(path.join(eventsPath, 'auth.yaml'));
      await yamlFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: Login\n'
        '    parameters:\n'
        '      Method: string\n' // Error 1: Invalid parameter name
        '  logout:\n'
        '    description: Logout\n'
        '    parameters: 123\n', // Error 2: Parameters not a map
      );

      final parser = YamlParser(eventsPath: eventsPath);

      try {
        await parser.parseEvents();
        fail('Should have thrown AnalyticsAggregateException');
      } on AnalyticsAggregateException catch (e) {
        expect(e.errors.length, equals(2));
        expect(e.errors[0].message,
            contains('violates the configured naming strategy'));
        expect(e.errors[1].message, contains('Parameters for event'));
      }
    });

    test('collects errors from multiple files', () async {
      final file1 = File(path.join(eventsPath, 'auth.yaml'));
      await file1.writeAsString('auth: 123\n'); // Error 1: Domain not a map

      final file2 = File(path.join(eventsPath, 'screen.yaml'));
      await file2.writeAsString(
          'screen:\n  view:\n    parameters: 1\n'); // Error 2: Params not map

      final parser = YamlParser(eventsPath: eventsPath);

      try {
        await parser.parseEvents();
        fail('Should have thrown AnalyticsAggregateException');
      } on AnalyticsAggregateException catch (e) {
        expect(e.errors.length, equals(2));
        expect(e.errors.any((err) => err.message.contains('Domain "auth"')),
            isTrue);
        expect(
            e.errors.any((err) => err.message.contains('Parameters for event')),
            isTrue);
      }
    });

    test('collects duplicate identifier errors across domains', () async {
      final file1 = File(path.join(eventsPath, 'auth.yaml'));
      await file1.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: Login\n'
        '    event_name: user.login\n'
        '    parameters: {}\n',
      );

      final file2 = File(path.join(eventsPath, 'purchase.yaml'));
      await file2.writeAsString(
        'purchase:\n'
        '  complete:\n'
        '    description: Purchase\n'
        '    event_name: user.login\n' // Duplicate
        '    parameters: {}\n',
      );

      final parser = YamlParser(eventsPath: eventsPath);

      try {
        await parser.parseEvents();
        fail('Should have thrown AnalyticsAggregateException');
      } on AnalyticsAggregateException catch (e) {
        expect(e.errors.length, equals(1));
        expect(e.errors.first.message,
            contains('Duplicate analytics event identifier'));
      }
    });
  });
}
