/// Telemetry callbacks for tracking generation performance.
///
/// Use these callbacks to monitor generation performance, identify bottlenecks,
/// and collect metrics for optimization.
abstract class GenerationTelemetry {
  const GenerationTelemetry();

  /// Called when generation starts.
  ///
  /// [context] contains information about the generation request.
  void onGenerationStart(GenerationContext context) {}

  /// Called when a domain has been processed.
  ///
  /// [domainName] is the name of the domain that was processed.
  /// [elapsed] is the duration it took to process this domain.
  /// [eventCount] is the number of events in the domain.
  void onDomainProcessed(
    String domainName,
    Duration elapsed,
    int eventCount,
  ) {}

  /// Called when a context has been processed.
  ///
  /// [contextName] is the name of the context that was processed.
  /// [elapsed] is the duration it took to process this context.
  /// [propertyCount] is the number of properties in the context.
  void onContextProcessed(
    String contextName,
    Duration elapsed,
    int propertyCount,
  ) {}

  /// Called when generation completes successfully.
  ///
  /// [elapsed] is the total duration of generation.
  /// [filesGenerated] is the number of files that were written.
  void onGenerationComplete(Duration elapsed, int filesGenerated) {}

  /// Called when generation fails.
  ///
  /// [error] is the error that caused the failure.
  /// [stackTrace] is the stack trace of the error.
  /// [elapsed] is the duration before the error occurred.
  void onGenerationError(
      Object error, StackTrace stackTrace, Duration elapsed) {}
}

/// Context information about the generation request.
class GenerationContext {
  final int domainCount;
  final int contextCount;
  final int totalEventCount;
  final int totalParameterCount;
  final bool generateDocs;
  final bool generateExports;
  final bool generateCode;

  const GenerationContext({
    required this.domainCount,
    required this.contextCount,
    required this.totalEventCount,
    required this.totalParameterCount,
    required this.generateDocs,
    required this.generateExports,
    required this.generateCode,
  });

  @override
  String toString() => 'GenerationContext('
      'domains: $domainCount, '
      'contexts: $contextCount, '
      'events: $totalEventCount, '
      'parameters: $totalParameterCount, '
      'docs: $generateDocs, '
      'exports: $generateExports, '
      'code: $generateCode)';
}

/// Default implementation that logs telemetry to a callback.
class LoggingTelemetry extends GenerationTelemetry {
  final void Function(String message) log;

  const LoggingTelemetry(this.log);

  @override
  void onGenerationStart(GenerationContext context) {
    log('Starting generation: $context');
  }

  @override
  void onDomainProcessed(
    String domainName,
    Duration elapsed,
    int eventCount,
  ) {
    log(
      'Processed domain "$domainName" '
      '($eventCount events) in ${elapsed.inMilliseconds}ms',
    );
  }

  @override
  void onContextProcessed(
    String contextName,
    Duration elapsed,
    int propertyCount,
  ) {
    log(
      'Processed context "$contextName" '
      '($propertyCount properties) in ${elapsed.inMilliseconds}ms',
    );
  }

  @override
  void onGenerationComplete(Duration elapsed, int filesGenerated) {
    log(
      'Generation completed successfully: '
      '$filesGenerated files in ${elapsed.inMilliseconds}ms',
    );
  }

  @override
  void onGenerationError(
      Object error, StackTrace stackTrace, Duration elapsed) {
    log(
      'Generation failed after ${elapsed.inMilliseconds}ms: $error',
    );
  }
}

/// No-op implementation that does nothing.
class NoOpTelemetry extends GenerationTelemetry {
  const NoOpTelemetry();
}
