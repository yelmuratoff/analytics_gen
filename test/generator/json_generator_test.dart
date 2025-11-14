import 'dart:convert';
import 'dart:io';

import 'package:analytics_gen/src/generator/export/json_generator.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
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
                ),
              ],
            ),
          ],
        ),
      };

      final generator = JsonGenerator();
      await generator.generate(domains, tempDir.path);

      final prettyFile = File(p.join(tempDir.path, 'analytics_events.json'));
      final minFile = File(p.join(tempDir.path, 'analytics_events.min.json'));

      expect(prettyFile.existsSync(), isTrue);
      expect(minFile.existsSync(), isTrue);

      final prettyJson = jsonDecode(await prettyFile.readAsString())
          as Map<String, dynamic>;

      expect(prettyJson['metadata']['total_domains'], equals(1));
      expect(prettyJson['metadata']['total_events'], equals(1));
      expect(prettyJson['metadata']['total_parameters'], equals(1));

      final domainsJson = prettyJson['domains'] as List<dynamic>;
      expect(domainsJson, hasLength(1));
      final authDomain = domainsJson.first as Map<String, dynamic>;
      expect(authDomain['name'], equals('auth'));

      final eventsJson = authDomain['events'] as List<dynamic>;
      final login = eventsJson.first as Map<String, dynamic>;
      expect(login['deprecated'], isTrue);
      expect(login['replacement'], equals('auth.login_v2'));
    });
  });
}
