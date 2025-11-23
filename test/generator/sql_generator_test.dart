import 'dart:io';

import 'package:analytics_gen/src/config/naming_strategy.dart';
import 'package:analytics_gen/src/generator/export/sql_generator.dart';
import 'package:analytics_gen/src/generator/generation_metadata.dart';
import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('SqlGenerator', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('analytics_gen_sql_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('generates SQL schema and inserts for domains and events', () async {
      final domains = <String, AnalyticsDomain>{
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [
            const AnalyticsEvent(
              name: 'login',
              description: 'User logs in',
              parameters: [
                AnalyticsParameter(
                  name: 'method',
                  type: 'string',
                  isNullable: false,
                ),
              ],
            ),
          ],
        ),
      };

      final outputPath = p.join(tempDir.path, 'create_database.sql');
      final generator = SqlGenerator(naming: const NamingStrategy());

      await generator.generate(domains, outputPath);

      final sqlFile = File(outputPath);
      expect(sqlFile.existsSync(), isTrue);

      final sql = await sqlFile.readAsString();
      final metadata = GenerationMetadata.fromDomains(domains);

      // Basic schema
      expect(sql, contains('CREATE TABLE IF NOT EXISTS domains'));
      expect(sql, contains('CREATE TABLE IF NOT EXISTS events'));
      expect(sql, contains('CREATE TABLE IF NOT EXISTS parameters'));

      // Inserts for domain and event
      expect(sql, contains('INSERT INTO domains'));
      expect(sql, contains('auth'));
      expect(sql, contains('INSERT INTO events'));
      expect(sql, contains('login'));
      expect(sql, contains('INSERT INTO parameters'));
      expect(sql, contains('method'));

      // Deprecated column presence
      expect(sql, contains('deprecated INTEGER NOT NULL DEFAULT 0'));
      expect(sql, contains('-- Fingerprint: ${metadata.fingerprint}'));
    });

    test('escapes parameter descriptions and allowed values', () async {
      final domains = <String, AnalyticsDomain>{
        'billing': AnalyticsDomain(
          name: 'billing',
          events: [
            AnalyticsEvent(
              name: 'purchase',
              description: 'Completes purchase',
              parameters: [
                AnalyticsParameter(
                  name: 'plan',
                  type: 'string',
                  isNullable: false,
                  description: "Plan with 'quote' and comma, yes",
                  allowedValues: ['basic', 'premium,plus', "o'clock"],
                ),
              ],
            ),
          ],
        ),
      };

      final outputPath = p.join(tempDir.path, 'create_database.sql');
      final generator = SqlGenerator(naming: const NamingStrategy());

      await generator.generate(domains, outputPath);
      final sql = await File(outputPath).readAsString();

      expect(
        sql,
        contains(
          "VALUES (1, 'plan', 'string', 0, 'Plan with ''quote'' and comma, yes', 'basic, premium,plus, o''clock');",
        ),
      );
    });

    test('writes reproducible SQL across runs', () async {
      final domains = <String, AnalyticsDomain>{
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [
            const AnalyticsEvent(
              name: 'login',
              description: 'User logs in',
              parameters: [
                AnalyticsParameter(
                  name: 'method',
                  type: 'string',
                  isNullable: false,
                ),
              ],
            ),
          ],
        ),
      };

      final outputPath = p.join(tempDir.path, 'create_database.sql');
      final generator = SqlGenerator(naming: const NamingStrategy());

      await generator.generate(domains, outputPath);
      final first = await File(outputPath).readAsString();

      await Future<void>.delayed(const Duration(milliseconds: 5));

      await generator.generate(domains, outputPath);
      final second = await File(outputPath).readAsString();

      expect(second, equals(first));
    });
  });
}
