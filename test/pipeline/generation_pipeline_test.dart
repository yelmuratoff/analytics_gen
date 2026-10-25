import 'dart:io';

import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/core/exceptions.dart';
import 'package:analytics_gen/src/pipeline/generation_pipeline.dart';
import 'package:analytics_gen/src/pipeline/generation_request.dart';
import 'package:analytics_gen/src/services/watcher_service.dart';
import 'package:analytics_gen/src/util/logger.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../test_utils.dart';

final class _RepeatingWatcherService implements WatcherService {
  _RepeatingWatcherService(this.runs);

  final int runs;

  @override
  String get projectRoot => '';

  @override
  Logger get logger => const NoOpLogger();

  @override
  Future<void> watch({
    required String eventsPath,
    required Future<void> Function() onGenerate,
  }) async {
    for (var i = 0; i < runs; i++) {
      await onGenerate();
    }
  }
}

void main() {
  group('GenerationPipeline', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('generation_pipeline_');
      Directory(p.join(tempDir.path, 'events')).createSync();
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    void writeEvents(String content) =>
        File(p.join(tempDir.path, 'events', 'auth.yaml'))
            .writeAsStringSync(content);

    GenerationPipeline pipeline({WatcherService? watcherService}) =>
        GenerationPipeline(
          projectRoot: tempDir.path,
          config: AnalyticsConfig(
            inputs: AnalyticsInputs(eventsPath: 'events'),
            outputs: AnalyticsOutputs(dartPath: 'lib/analytics'),
          ),
          watcherService: watcherService,
          logger: const NoOpLogger(),
        );

    GenerationRequest codeRequest(List<String> logs) => GenerationRequest(
          generateCode: true,
          generateDocs: false,
          generateExports: false,
          verbose: false,
          logger: TestLogger(logs),
        );

    const collidingEnum = 'auth:\n'
        '  login:\n'
        '    description: Login\n'
        '    parameters:\n'
        '      channel:\n'
        '        type: string\n'
        '        allowed_values: [Email, email]\n';

    test('throws the typed generation error instead of exiting', () async {
      writeEvents(collidingEnum);

      await expectLater(
        pipeline().run(codeRequest([])),
        throwsA(isA<AnalyticsGenerationException>()),
      );
    });

    test('throws the parse error for an invalid tracking plan', () async {
      writeEvents('auth:\n'
          '  login:\n'
          '    description: Login\n'
          '    parameters:\n'
          '      flow_idd:\n');

      await expectLater(
        pipeline().run(codeRequest([])),
        throwsA(isA<AnalyticsAggregateException>()),
      );
    });

    test('names the task when it fails with an unexpected error', () async {
      writeEvents('auth:\n  login:\n    description: Login\n');
      File(p.join(tempDir.path, 'lib', 'analytics'))
        ..createSync(recursive: true)
        ..writeAsStringSync('a file where the output directory should be');

      await expectLater(
        pipeline().run(codeRequest([])),
        throwsA(
          isA<AnalyticsGenerationException>().having(
            (e) => e.message,
            'message',
            startsWith('Code generation failed: '),
          ),
        ),
      );
    });

    test('keeps watching and reports each failed regeneration', () async {
      writeEvents(collidingEnum);
      final logs = <String>[];

      await pipeline(watcherService: _RepeatingWatcherService(2))
          .watch(codeRequest(logs));

      expect(
        logs.where((line) => line.startsWith('✗ Generation failed:')),
        hasLength(2),
      );
    });
  });
}
