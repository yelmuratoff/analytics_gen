import 'dart:io';

import 'package:analytics_gen/src/generator/export/csv_generator.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('CsvGenerator', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('analytics_gen_csv_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('includes deprecation and allowed_values metadata', () async {
      final domains = <String, AnalyticsDomain>{
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [
            const AnalyticsEvent(
              name: 'login',
              description: 'User logs in',
              deprecated: true,
              replacement: 'auth.login_v2',
              parameters: [
                AnalyticsParameter(
                  name: 'method',
                  type: 'string',
                  isNullable: false,
                  allowedValues: ['email', 'google'],
                ),
              ],
            ),
          ],
        ),
      };

      final outputPath = p.join(tempDir.path, 'events.csv');
      final generator = CsvGenerator();

      await generator.generate(domains, outputPath);

      final csv = await File(outputPath).readAsString();

      expect(
        csv.split('\n').first,
        contains('Deprecated'),
      );
      expect(csv, contains('true')); // deprecated flag
      expect(csv, contains('auth.login_v2')); // replacement
      expect(csv, contains('{allowed: email|google}'));
    });
  });
}

