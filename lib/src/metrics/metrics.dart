/// Interface for recording performance metrics during generation.
abstract interface class Metrics {
  /// Records the duration of the parsing phase.
  void recordParsing(Duration elapsed, int domainCount, int eventCount);

  /// Records how long the generation tasks took together.
  void recordGeneration(Duration elapsed);
}

/// No-op implementation of [Metrics].
class NoOpMetrics implements Metrics {
  /// Creates a new no-op metrics recorder.
  const NoOpMetrics();

  @override
  void recordGeneration(Duration elapsed) {}

  @override
  void recordParsing(Duration elapsed, int domainCount, int eventCount) {}
}
