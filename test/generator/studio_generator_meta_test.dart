import 'dart:convert';
import 'dart:io';

import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/generator/studio_generator.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('StudioGenerator meta block', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('studio_meta_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    Future<Map<String, dynamic>> generate() async {
      final generator = StudioGenerator(
        config: AnalyticsConfig.defaultConfig,
        projectRoot: tempDir.path,
        configPath: 'analytics_gen.yaml',
      );
      final file = await generator.generate(outputPath: 'out.json');
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }

    test('emits a revision and no projectId on first generation', () async {
      final json = await generate();
      final meta = json['meta'] as Map<String, dynamic>;

      // Empty project content matches the locked cross-language reference hash.
      expect(meta['revision'], '07f86068ecf134');
      expect(meta.containsKey('projectId'), isFalse);
    });

    test('preserves projectId/name across regenerations, revision stays stable',
        () async {
      final first = await generate();
      final firstRevision = (first['meta'] as Map)['revision'];

      // Simulate an identity assigned by the studio or a prior commit.
      final outFile = File(p.join(tempDir.path, 'out.json'));
      final mutated =
          jsonDecode(outFile.readAsStringSync()) as Map<String, dynamic>;
      (mutated['meta'] as Map)['projectId'] = 'proj-fixed';
      (mutated['meta'] as Map)['name'] = 'Checkout';
      outFile.writeAsStringSync(jsonEncode(mutated));

      final second = await generate();
      final secondMeta = second['meta'] as Map<String, dynamic>;

      expect(secondMeta['projectId'], 'proj-fixed');
      expect(secondMeta['name'], 'Checkout');
      expect(secondMeta['revision'], firstRevision);
    });
  });
}
