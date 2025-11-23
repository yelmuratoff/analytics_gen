import 'dart:convert';
import 'dart:io';

import 'package:analytics_gen/src/config/naming_strategy.dart';
import 'package:analytics_gen/src/generator/export/json_generator.dart';
import 'package:analytics_gen/src/generator/generation_metadata.dart';
import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('JsonGenerator', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('analytics_gen_json_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('writes pretty and minified JSON with correct metadata', () async {
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
                  allowedValues: ['email', 'google', 'apple'],
                ),
              ],
            ),
          ],
        ),
      };

      final generator = JsonGenerator(naming: const NamingStrategy());
      await generator.generate(domains, tempDir.path);

      final prettyFile = File(p.join(tempDir.path, 'analytics_events.json'));
      final minFile = File(p.join(tempDir.path, 'analytics_events.min.json'));

      expect(prettyFile.existsSync(), isTrue);
      expect(minFile.existsSync(), isTrue);

      final prettyJson =
          jsonDecode(await prettyFile.readAsString()) as Map<String, dynamic>;

      final metadata = GenerationMetadata.fromDomains(domains);
      expect(prettyJson['metadata']['total_domains'], equals(1));
      expect(prettyJson['metadata']['total_events'], equals(1));
      expect(prettyJson['metadata']['total_parameters'], equals(1));
      expect(prettyJson['metadata']['fingerprint'], metadata.fingerprint);

      final domainsJson = prettyJson['domains'] as List<dynamic>;
      expect(domainsJson, hasLength(1));
      final authDomain = domainsJson.first as Map<String, dynamic>;
      expect(authDomain['name'], equals('auth'));

      final eventsJson = authDomain['events'] as List<dynamic>;
      final login = eventsJson.first as Map<String, dynamic>;
      expect(login['deprecated'], isTrue);
      expect(login['replacement'], equals('auth.login_v2'));
      final paramsJson = login['parameters'] as List<dynamic>;
      final method = paramsJson.first as Map<String, dynamic>;
      expect(method['allowed_values'], equals(['email', 'google', 'apple']));
    });

    test('writes identical JSON outputs across runs', () async {
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
        'screen': AnalyticsDomain(
          name: 'screen',
          events: [
            const AnalyticsEvent(
              name: 'view',
              description: 'Screen view',
              parameters: [
                AnalyticsParameter(
                  name: 'screen_name',
                  type: 'string',
                  isNullable: false,
                ),
              ],
            ),
          ],
        ),
      };

      final generator = JsonGenerator(naming: const NamingStrategy());
      await generator.generate(domains, tempDir.path);

      final prettyFirst =
          await File(p.join(tempDir.path, 'analytics_events.json'))
              .readAsString();
      final minifiedFirst =
          await File(p.join(tempDir.path, 'analytics_events.min.json'))
              .readAsString();

      await Future<void>.delayed(const Duration(milliseconds: 5));

      await generator.generate(domains, tempDir.path);

      final prettySecond =
          await File(p.join(tempDir.path, 'analytics_events.json'))
              .readAsString();
      final minifiedSecond =
          await File(p.join(tempDir.path, 'analytics_events.min.json'))
              .readAsString();

      expect(prettySecond, equals(prettyFirst));
      expect(minifiedSecond, equals(minifiedFirst));
    });

    test('includes deprecated_in and dual_write_to when set on events',
        () async {
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
              deprecatedIn: '1.2.3',
              dualWriteTo: ['auth.legacy_login', 'tracking.login'],
            ),
          ],
        ),
      };

      final generator = JsonGenerator(naming: const NamingStrategy());
      await generator.generate(domains, tempDir.path);

      final prettyJson = jsonDecode(
          await File(p.join(tempDir.path, 'analytics_events.json'))
              .readAsString()) as Map<String, dynamic>;

      final domainsJson = prettyJson['domains'] as List<dynamic>;
      final authDomain = domainsJson.first as Map<String, dynamic>;
      final eventsJson = authDomain['events'] as List<dynamic>;
      final login = eventsJson.first as Map<String, dynamic>;

      expect(login['deprecated_in'], equals('1.2.3'));
      expect(login['dual_write_to'],
          equals(['auth.legacy_login', 'tracking.login']));
    });

    test('omits dual_write_to when empty list is provided', () async {
      final domains = <String, AnalyticsDomain>{
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [
            const AnalyticsEvent(
              name: 'logout',
              description: 'User logs out',
              parameters: [
                AnalyticsParameter(
                  name: 'method',
                  type: 'string',
                  isNullable: false,
                ),
              ],
              dualWriteTo: [],
            ),
          ],
        ),
      };

      final generator = JsonGenerator(naming: const NamingStrategy());
      await generator.generate(domains, tempDir.path);

      final prettyJson = jsonDecode(
          await File(p.join(tempDir.path, 'analytics_events.json'))
              .readAsString()) as Map<String, dynamic>;

      final domainsJson = prettyJson['domains'] as List<dynamic>;
      final authDomain = domainsJson.first as Map<String, dynamic>;
      final eventsJson = authDomain['events'] as List<dynamic>;
      final logout = eventsJson.first as Map<String, dynamic>;

      expect(logout.containsKey('dual_write_to'), isFalse);
    });
  });
}
