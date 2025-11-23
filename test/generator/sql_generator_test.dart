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
            AnalyticsEvent(
              name: 'login',
              description: 'User logs in',
              identifier: 'event-id',
              customEventName: 'auth_login_custom',
              parameters: [
                AnalyticsParameter(
                  name: 'method',
                  sourceName: 'method_raw',
                  codeName: 'methodCode',
                  type: 'string',
                  isNullable: false,
                  description: 'Auth method',
                  allowedValues: const ['password', 'sso'],
                  regex: r'^[a-z]+$',
                  minLength: 3,
                  maxLength: 10,
                  min: 1,
                  max: 5,
                  operations: const ['set', 'unset'],
                  addedIn: '1.0.0',
                  deprecatedIn: '2.0.0',
                  meta: const {'pii': false},
                ),
              ],
              deprecated: true,
              replacement: 'auth.logout',
              meta: const {'owner': 'growth'},
              addedIn: '1.0.0',
              deprecatedIn: '2.0.0',
              dualWriteTo: const ['legacy.auth.login'],
              sourcePath: '/tmp/events/auth.yaml',
              lineNumber: 12,
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
      expect(sql, contains('identifier TEXT NOT NULL'));
      expect(sql, contains('custom_event_name TEXT'));
      expect(sql, contains('code_name TEXT NOT NULL'));
      expect(sql, contains('operations TEXT'));

      // Inserts for domain and event
      expect(sql, contains('INSERT INTO domains'));
      expect(sql, contains('auth'));
      expect(sql, contains('INSERT INTO events'));
      expect(
        sql,
        contains(
          r'''INSERT INTO events (id, domain_id, name, event_name, identifier, description, deprecated, replacement, added_in, deprecated_in, custom_event_name, dual_write_to, meta, source_path, line_number) VALUES (1, 1, 'login', 'auth_login_custom', 'event-id', 'User logs in', 1, 'auth.logout', '1.0.0', '2.0.0', 'auth_login_custom', '["legacy.auth.login"]', '{"owner":"growth"}', '/tmp/events/auth.yaml', 12);''',
        ),
      );

      expect(sql, contains('INSERT INTO parameters'));
      expect(
        sql,
        contains(
          r'''INSERT INTO parameters (event_id, name, source_name, code_name, type, nullable, description, allowed_values, regex, min_length, max_length, min, max, operations, added_in, deprecated_in, meta) VALUES (1, 'method', 'method_raw', 'methodCode', 'string', 0, 'Auth method', '["password","sso"]', '^[a-z]+$', 3, 10, 1, 5, '["set","unset"]', '1.0.0', '2.0.0', '{"pii":false}');''',
        ),
      );

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
          r'''VALUES (1, 'plan', NULL, 'plan', 'string', 0, 'Plan with ''quote'' and comma, yes', '["basic","premium,plus","o''clock"]', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);''',
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
