import 'dart:io';

import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/generator/docs_generator.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late String projectRoot;
  late AnalyticsConfig config;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('analytics_gen_test_');
    projectRoot = tempDir.path;
    config = AnalyticsConfig(
      inputs: AnalyticsInputs(eventsPath: 'events'),
      outputs: AnalyticsOutputs(docsPath: 'docs/analytics.md'),
    );
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test('generate includes user properties and global context in docs',
      () async {
    final generator = DocsGenerator(
      config: config,
      projectRoot: projectRoot,
    );

    final userProperties = [
      AnalyticsParameter(
        name: 'role',
        type: 'String',
        isNullable: false,
        description: 'User role',
      ),
    ];
    final globalContext = [
      AnalyticsParameter(
        name: 'version',
        type: 'String',
        isNullable: false,
        description: 'App version',
      ),
    ];

    await generator.generate(
      {},
      contexts: {
        'user_properties': userProperties,
        'global_context': globalContext,
      },
    );

    final docsFile = File(path.join(projectRoot, config.outputs.docsPath!));
    expect(docsFile.existsSync(), isTrue);

    final content = docsFile.readAsStringSync();
    expect(content, contains('## User Properties'));
    expect(content, contains('| role | String | User role | - | - |'));
    expect(content, contains('## Global Context'));
    expect(content, contains('| version | String | App version | - | - |'));
  });
}
