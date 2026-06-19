import 'dart:convert';
import 'dart:io';

import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/generator/studio_generator.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Exercises the raw-YAML readers in-process. The CLI integration test runs the
/// generator in a subprocess, which the coverage collector cannot instrument —
/// these tests cover the reader/conversion logic directly.
void main() {
  group('StudioGenerator readers', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('studio_readers_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    void write(String relativePath, String contents) {
      final file = File(p.join(tempDir.path, relativePath));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(contents);
    }

    const config = AnalyticsConfig(
      inputs: AnalyticsInputs(
        eventsPath: 'events',
        sharedParameters: ['events/shared_user.yaml'],
        contexts: ['events/user_properties.yaml'],
      ),
    );

    void scaffold() {
      // A flat scalar alias (`version`) must be stripped; Map sections stay.
      write('analytics_gen.yaml', '''
analytics_gen:
  inputs:
    events: events
  outputs:
    studio: analytics-studio.json
  targets:
    studio: true
  version: 7
''');

      write('events/auth.yaml', '''
auth:
  login:
    description: User logs in
    parameters:
      method:
        type: string
        allowed_values: ["email", "google"]
      session_id:
  bad_event: not_a_map
top_scalar: just_a_string
''');

      write('events/checkout.yaml', '''
checkout:
  purchase:
    description: User completes a purchase
    parameters:
      amount:
        type: double
''');

      write('events/shared_user.yaml', '''
parameters:
  session_id:
    type: String
    allowed_values: ["a", "b"]
''');

      write('events/user_properties.yaml', '''
user_properties:
  user_id:
    type: String
  login_count:
    type: int
    operations: [set, increment]
''');
    }

    Future<Map<String, dynamic>> generate({String? outputPath}) async {
      final generator = StudioGenerator(
        config: config,
        projectRoot: tempDir.path,
        configPath: 'analytics_gen.yaml',
      );
      final file = await generator.generate(outputPath: outputPath);
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }

    test('reads config sections and strips flat scalar aliases', () async {
      scaffold();
      final json = await generate(outputPath: 'out.json');
      final cfg = json['config'] as Map<String, dynamic>;

      expect(cfg.keys, containsAll(['inputs', 'outputs', 'targets']));
      expect(cfg.containsKey('version'), isFalse,
          reason: 'Scalar top-level aliases must be removed');
      expect(cfg['inputs']['events'], 'events');
    });

    test('converts event domains and skips non-map entries', () async {
      scaffold();
      final json = await generate(outputPath: 'out.json');
      final eventFiles = json['eventFiles'] as List;

      final auth = eventFiles.firstWhere(
        (f) => (f as Map)['fileName'] == 'auth.yaml',
        orElse: () => fail('auth.yaml missing'),
      ) as Map<String, dynamic>;

      final authDomain = auth['domains']['auth'] as Map<String, dynamic>;
      final login = authDomain['login'] as Map<String, dynamic>;

      expect(
          login['parameters']['method']['allowed_values'], ['email', 'google']);
      // Empty value is the shorthand for a shared-parameter reference.
      expect(login['parameters'].containsKey('session_id'), isTrue);
      expect(login['parameters']['session_id'], isNull);

      expect(authDomain.containsKey('bad_event'), isFalse);
      expect(auth['domains'].containsKey('top_scalar'), isFalse);
    });

    test('sorts event files and excludes shared/context files', () async {
      scaffold();
      final json = await generate(outputPath: 'out.json');
      final names = (json['eventFiles'] as List)
          .map((f) => (f as Map)['fileName'] as String)
          .toList();

      expect(names, ['auth.yaml', 'checkout.yaml']);
      expect(names, isNot(contains('shared_user.yaml')));
      expect(names, isNot(contains('user_properties.yaml')));
    });

    test('reads shared parameter files', () async {
      scaffold();
      final json = await generate(outputPath: 'out.json');
      final shared =
          (json['sharedParamFiles'] as List).single as Map<String, dynamic>;

      expect(shared['fileName'], 'shared_user.yaml');
      expect(shared['parameters']['session_id']['allowed_values'], ['a', 'b']);
    });

    test('reads context files with their name and properties', () async {
      scaffold();
      final json = await generate(outputPath: 'out.json');
      final context =
          (json['contextFiles'] as List).single as Map<String, dynamic>;

      expect(context['fileName'], 'user_properties.yaml');
      expect(context['contextName'], 'user_properties');
      expect(context['properties']['login_count']['operations'],
          contains('increment'));
    });

    test('writes to config.outputs.studioPath when no outputPath is given',
        () async {
      scaffold();
      await generate();

      final defaultOutput =
          File(p.join(tempDir.path, config.outputs.studioPath));
      expect(defaultOutput.existsSync(), isTrue);
    });
  });

  group('StudioGenerator reader fallbacks', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('studio_fallback_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    void write(String relativePath, String contents) {
      final file = File(p.join(tempDir.path, relativePath));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(contents);
    }

    Future<Map<String, dynamic>> generateWith(AnalyticsConfig config) async {
      final generator = StudioGenerator(
        config: config,
        projectRoot: tempDir.path,
        configPath: 'analytics_gen.yaml',
      );
      final file = await generator.generate(outputPath: 'out.json');
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }

    test('falls back to empty parameters on malformed shared file', () async {
      write('events/.keep', '');
      write('shared_broken.yaml', 'parameters: [unclosed');

      final json = await generateWith(
        const AnalyticsConfig(
          inputs: AnalyticsInputs(sharedParameters: ['shared_broken.yaml']),
        ),
      );

      final shared =
          (json['sharedParamFiles'] as List).single as Map<String, dynamic>;
      expect(shared['fileName'], 'shared_broken.yaml');
      expect(shared['parameters'], isEmpty);
    });

    test('falls back to empty parameters on empty shared file', () async {
      write('events/.keep', '');
      write('shared_empty.yaml', '');

      final json = await generateWith(
        const AnalyticsConfig(
          inputs: AnalyticsInputs(sharedParameters: ['shared_empty.yaml']),
        ),
      );

      final shared =
          (json['sharedParamFiles'] as List).single as Map<String, dynamic>;
      expect(shared['parameters'], isEmpty);
    });

    test('falls back to an empty context entry for a missing file', () async {
      write('events/.keep', '');

      final json = await generateWith(
        const AnalyticsConfig(
          inputs: AnalyticsInputs(contexts: ['does_not_exist.yaml']),
        ),
      );

      final context =
          (json['contextFiles'] as List).single as Map<String, dynamic>;
      expect(context['fileName'], 'does_not_exist.yaml');
      expect(context['contextName'], '');
      expect(context['properties'], isEmpty);
    });
  });
}
