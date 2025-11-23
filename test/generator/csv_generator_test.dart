import 'dart:io';

import 'package:analytics_gen/src/config/naming_strategy.dart';
import 'package:analytics_gen/src/generator/export/csv_generator.dart';
import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';
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

      final outputDir = tempDir.path;
      await CsvGenerator(naming: const NamingStrategy())
          .generate(domains, outputDir);

      final eventsCsv =
          await File(p.join(outputDir, 'analytics_events.csv')).readAsString();
      final paramsCsv =
          await File(p.join(outputDir, 'analytics_parameters.csv'))
              .readAsString();

      expect(eventsCsv, contains('"domain,with,comma"'));
      expect(eventsCsv, contains('login""event'));
      expect(eventsCsv,
          contains('"Description with comma, newline\nand ""quote"""'));

      expect(paramsCsv, contains('method'));
      expect(paramsCsv, contains('email|google'));
      expect(paramsCsv, contains('"Param desc, newline\nand ""quote"""'));
    });

    test('generates all CSV files', () async {
      final domains = {
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [
            AnalyticsEvent(
              name: 'login',
              description: 'User login',
              parameters: [
                const AnalyticsParameter(
                  name: 'method',
                  type: 'string',
                  isNullable: false,
                  regex: '^[a-z]+\$',
                  meta: {'pii': true},
                  addedIn: '1.0.0',
                ),
              ],
              meta: {'owner': 'auth-team'},
              addedIn: '1.0.0',
            ),
          ],
        ),
      };

      final outputDir = tempDir.path;
      await CsvGenerator(naming: const NamingStrategy())
          .generate(domains, outputDir);

      expect(
          File(p.join(outputDir, 'analytics_events.csv')).existsSync(), isTrue);
      expect(File(p.join(outputDir, 'analytics_parameters.csv')).existsSync(),
          isTrue);
      expect(File(p.join(outputDir, 'analytics_metadata.csv')).existsSync(),
          isTrue);
      expect(
          File(p.join(outputDir, 'analytics_event_parameters.csv'))
              .existsSync(),
          isTrue);
      expect(
          File(p.join(outputDir, 'analytics_master.csv')).existsSync(), isTrue);
      expect(File(p.join(outputDir, 'analytics_domains.csv')).existsSync(),
          isTrue);

      final eventsCsv =
          await File(p.join(outputDir, 'analytics_events.csv')).readAsString();
      expect(eventsCsv, contains('1.0.0')); // AddedIn

      final paramsCsv =
          await File(p.join(outputDir, 'analytics_parameters.csv'))
              .readAsString();
      expect(paramsCsv, contains('regex:^[a-z]+\$'));
      expect(paramsCsv, contains('pii=true'));
      expect(paramsCsv, contains('1.0.0')); // AddedIn

      final metaCsv = await File(p.join(outputDir, 'analytics_metadata.csv'))
          .readAsString();
      expect(metaCsv, contains('owner,auth-team'));

      final masterCsv =
          await File(p.join(outputDir, 'analytics_master.csv')).readAsString();
      expect(masterCsv, contains('auth,auth: login,User login'));
      expect(masterCsv, contains('method,string,false'));

      final domainsCsv =
          await File(p.join(outputDir, 'analytics_domains.csv')).readAsString();
      expect(domainsCsv, contains('auth,1,1'));
    });
  });
}
