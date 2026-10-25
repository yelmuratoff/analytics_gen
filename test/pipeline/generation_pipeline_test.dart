import 'dart:io';

import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/core/exceptions.dart';
import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/pipeline/generation_pipeline.dart';
import 'package:analytics_gen/src/pipeline/generation_request.dart';
import 'package:analytics_gen/src/services/schema_evolution_checker.dart';
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

final class _RecordingSchemaChecker implements SchemaEvolutionChecker {
  _RecordingSchemaChecker(this.exportFile);

  final File exportFile;
  final List<bool> exportExistedAtCheck = [];

  @override
  String get projectRoot => '';

  @override
  Logger get logger => const NoOpLogger();

  @override
  Future<void> checkSchemaEvolution(
    Map<String, AnalyticsDomain> currentDomains,
    String? exportsPath,
  ) async {
    exportExistedAtCheck.add(exportFile.existsSync());
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

    test('checks schema evolution before the exports are rewritten', () async {
      writeEvents('auth:\n  login:\n    description: Login\n');
      final exportFile =
          File(p.join(tempDir.path, 'exports', 'analytics_events.json'));
      final checker = _RecordingSchemaChecker(exportFile);
      final exportingPipeline = GenerationPipeline(
        projectRoot: tempDir.path,
        config: AnalyticsConfig(
          inputs: AnalyticsInputs(eventsPath: 'events'),
          outputs: AnalyticsOutputs(
            dartPath: 'lib/analytics',
            exportsPath: 'exports',
          ),
          targets: AnalyticsTargets(generateJson: true),
        ),
        schemaChecker: checker,
        logger: const NoOpLogger(),
      );

      await exportingPipeline.run(GenerationRequest(
        generateCode: false,
        generateDocs: false,
        generateExports: true,
        verbose: false,
      ));

      expect(checker.exportExistedAtCheck, [false]);
      expect(exportFile.existsSync(), isTrue);
    });

    test('reports generation time in metrics without a file count', () async {
      writeEvents('auth:\n  login:\n    description: Login\n');
      final logs = <String>[];

      await pipeline().run(GenerationRequest(
        generateCode: true,
        generateDocs: false,
        generateExports: false,
        verbose: false,
        enableMetrics: true,
        logger: TestLogger(logs),
      ));

      expect(
        logs.where((line) => line.contains('[Metrics] Ran generation tasks')),
        hasLength(1),
      );
      expect(logs.where((line) => line.contains('Generated 0 files')), isEmpty);
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
