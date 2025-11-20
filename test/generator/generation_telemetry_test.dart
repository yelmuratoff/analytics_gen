import 'package:analytics_gen/src/generator/generation_telemetry.dart';
import 'package:test/test.dart';

void main() {
  group('GenerationTelemetry', () {
    test('GenerationContext toString includes all fields', () {
      final context = GenerationContext(
        domainCount: 3,
        contextCount: 2,
        totalEventCount: 10,
        totalParameterCount: 25,
        generateDocs: true,
        generateExports: true,
        generateCode: true,
      );

      final str = context.toString();
      expect(str, contains('domains: 3'));
      expect(str, contains('contexts: 2'));
      expect(str, contains('events: 10'));
      expect(str, contains('parameters: 25'));
      expect(str, contains('docs: true'));
      expect(str, contains('exports: true'));
      expect(str, contains('code: true'));
    });

    test('LoggingTelemetry logs generation start', () {
      final logs = <String>[];
      final telemetry = LoggingTelemetry(logs.add);

      final context = GenerationContext(
        domainCount: 2,
        contextCount: 1,
        totalEventCount: 5,
        totalParameterCount: 10,
        generateDocs: true,
        generateExports: true,
        generateCode: true,
      );

      telemetry.onGenerationStart(context);

      expect(logs, hasLength(1));
      expect(logs.first, contains('Starting generation'));
      expect(logs.first, contains('domains: 2'));
    });

    test('LoggingTelemetry logs domain processed', () {
      final logs = <String>[];
      final telemetry = LoggingTelemetry(logs.add);

      telemetry.onDomainProcessed(
        'auth',
        const Duration(milliseconds: 50),
        5,
      );

      expect(logs, hasLength(1));
      expect(logs.first, contains('Processed domain "auth"'));
      expect(logs.first, contains('5 events'));
      expect(logs.first, contains('50ms'));
    });

    test('LoggingTelemetry logs context processed', () {
      final logs = <String>[];
      final telemetry = LoggingTelemetry(logs.add);

      telemetry.onContextProcessed(
        'user_properties',
        const Duration(milliseconds: 10),
        3,
      );

      expect(logs, hasLength(1));
      expect(logs.first, contains('Processed context "user_properties"'));
      expect(logs.first, contains('3 properties'));
      expect(logs.first, contains('10ms'));
    });

    test('LoggingTelemetry logs generation complete', () {
      final logs = <String>[];
      final telemetry = LoggingTelemetry(logs.add);

      telemetry.onGenerationComplete(
        const Duration(milliseconds: 150),
        10,
      );

      expect(logs, hasLength(1));
      expect(logs.first, contains('Generation completed successfully'));
      expect(logs.first, contains('10 files'));
      expect(logs.first, contains('150ms'));
    });

    test('LoggingTelemetry logs generation error', () {
      final logs = <String>[];
      final telemetry = LoggingTelemetry(logs.add);

      telemetry.onGenerationError(
        Exception('Test error'),
        StackTrace.empty,
        const Duration(milliseconds: 100),
      );

      expect(logs, hasLength(1));
      expect(logs.first, contains('Generation failed'));
      expect(logs.first, contains('100ms'));
      expect(logs.first, contains('Test error'));
    });

    test('NoOpTelemetry does nothing', () {
      const telemetry = NoOpTelemetry();

      // These should not throw or cause any side effects
      telemetry.onGenerationStart(
        GenerationContext(
          domainCount: 0,
          contextCount: 0,
          totalEventCount: 0,
          totalParameterCount: 0,
          generateDocs: false,
          generateExports: false,
          generateCode: false,
        ),
      );
      telemetry.onDomainProcessed('test', Duration.zero, 0);
      telemetry.onContextProcessed('test', Duration.zero, 0);
      telemetry.onGenerationComplete(Duration.zero, 0);
      telemetry.onGenerationError(Exception(), StackTrace.empty, Duration.zero);

      // If we get here without errors, the test passes
      expect(true, isTrue);
    });

    test('Custom telemetry can extend base class', () {
      final tracker = _MetricsTracker();

      final context = GenerationContext(
        domainCount: 3,
        contextCount: 1,
        totalEventCount: 15,
        totalParameterCount: 40,
        generateDocs: true,
        generateExports: true,
        generateCode: true,
      );

      tracker.onGenerationStart(context);
      tracker.onDomainProcessed('auth', const Duration(milliseconds: 50), 5);
      tracker.onDomainProcessed('screen', const Duration(milliseconds: 30), 10);
      tracker.onContextProcessed('user', const Duration(milliseconds: 10), 3);
      tracker.onGenerationComplete(const Duration(milliseconds: 200), 12);

      expect(tracker.startCount, equals(1));
      expect(tracker.domainCount, equals(2));
      expect(tracker.contextCount, equals(1));
      expect(tracker.totalDomainTime.inMilliseconds, equals(80));
      expect(tracker.totalContextTime.inMilliseconds, equals(10));
      expect(tracker.completeCount, equals(1));
    });
  });
}

class _MetricsTracker extends GenerationTelemetry {
  int startCount = 0;
  int domainCount = 0;
  int contextCount = 0;
  int completeCount = 0;
  Duration totalDomainTime = Duration.zero;
  Duration totalContextTime = Duration.zero;

  @override
  void onGenerationStart(GenerationContext context) {
    startCount++;
  }

  @override
  void onDomainProcessed(String domainName, Duration elapsed, int eventCount) {
    domainCount++;
    totalDomainTime += elapsed;
  }

  @override
  void onContextProcessed(
    String contextName,
    Duration elapsed,
    int propertyCount,
  ) {
    contextCount++;
    totalContextTime += elapsed;
  }

  @override
  void onGenerationComplete(Duration elapsed, int filesGenerated) {
    completeCount++;
  }
}
