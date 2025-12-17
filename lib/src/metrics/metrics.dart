/// Interface for recording performance metrics during generation.
abstract interface class Metrics {
  /// Records the duration of the parsing phase.
  void recordParsing(Duration elapsed, int domainCount, int eventCount);

  /// Records the duration of the code generation phase.
  void recordGeneration(Duration elapsed, int fileCount);

  /// Records the duration of a validation check.
  void recordValidation(String checkName, Duration elapsed, int issueCount);
}

/// No-op implementation of [Metrics].
class NoOpMetrics implements Metrics {
  /// Creates a new no-op metrics recorder.
  const NoOpMetrics();

  @override
  void recordGeneration(Duration elapsed, int fileCount) {}

  @override
  void recordParsing(Duration elapsed, int domainCount, int eventCount) {}

  @override
  void recordValidation(String checkName, Duration elapsed, int issueCount) {}
}
