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

    test('escapes special characters and doubles quotes in fields', () async {
      final domains = {
        'domain,with,comma': AnalyticsDomain(
          name: 'domain,with,comma',
          events: [
            AnalyticsEvent(
              name: 'login"event',
              description: 'Description with comma, newline\nand "quote"',
              parameters: [
                const AnalyticsParameter(
                  name: 'method',
                  type: 'string',
                  isNullable: false,
                  description: 'Param desc, newline\nand "quote"',
                  allowedValues: ['email', 'google'],
                ),
              ],
              replacement: 'replacement,"with"quote',
            ),
          ],
        ),
      };

      final csvPath = p.join(tempDir.path, 'analytics_events.csv');
      await CsvGenerator().generate(domains, csvPath);

      final csvContent = await File(csvPath).readAsString();

      expect(csvContent, contains('"domain,with,comma"'));
      expect(csvContent, contains('"login""event"'));
      expect(csvContent, contains('and ""quote"" {allowed: email|google}'));
      expect(csvContent, contains('replacement,""with""quote'));
    });
  });
}
