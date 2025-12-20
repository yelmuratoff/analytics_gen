import '../util/logger.dart';
import 'metrics.dart';

/// Metrics recorder that outputs to the console via [Logger].
class ConsoleMetrics implements Metrics {
  /// Creates a new console metrics recorder.
  const ConsoleMetrics(this._logger);
  final Logger _logger;

  @override
  void recordParsing(Duration elapsed, int domainCount, int eventCount) {
    _logger.info(
      ' [Metrics] Parsed $eventCount events across $domainCount domains in ${elapsed.inMilliseconds}ms',
    );
  }

  @override
  void recordGeneration(Duration elapsed, int fileCount) {
    _logger.info(
      ' [Metrics] Generated $fileCount files in ${elapsed.inMilliseconds}ms',
    );
  }

  @override
  void recordValidation(String checkName, Duration elapsed, int issueCount) {
    _logger.info(
      ' [Metrics] Validation "$checkName" took ${elapsed.inMilliseconds}ms ($issueCount issues found)',
    );
  }
}
