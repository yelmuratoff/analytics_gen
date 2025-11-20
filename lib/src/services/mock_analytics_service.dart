import '../core/analytics_capabilities.dart';
import '../core/analytics_interface.dart';
import '../models/recorded_event.dart';
import '../util/logger.dart';

/// Mock analytics service for testing and development.
///
/// Records events in memory and provides query methods for verification.
final class MockAnalyticsService
    implements IAnalytics, AnalyticsCapabilityProvider {

  /// Creates a new mock analytics service.
  MockAnalyticsService({
    this.verbose = false,
    CapabilityRegistry? capabilities,
    Logger? logger,
  })  : _capabilities = capabilities ?? CapabilityRegistry(),
        _logger = logger ?? const ConsoleLogger();
  final List<RecordedAnalyticsEvent> _records = [];

  /// Whether to print events to console when logged
  final bool verbose;

  final CapabilityRegistry _capabilities;
  final Logger _logger;

  /// Immutable view of recorded events as typed records.
  List<RecordedAnalyticsEvent> get records => List.unmodifiable(_records);

  /// Legacy map-based view kept for backward compatibility.
  List<Map<String, Object?>> get events =>
      List.unmodifiable(_records.map((record) => record.toMap()));

  @override
  void logEvent({
    required String name,
    AnalyticsParams? parameters,
  }) {
    final normalizedParameters = Map<String, Object?>.unmodifiable(
        parameters ?? const <String, Object?>{});

    final record = RecordedAnalyticsEvent(
      name: name,
      parameters: normalizedParameters,
      timestamp: DateTime.now(),
    );

    _records.add(record);

    if (verbose) {
      _logger.info('[Analytics] $name $normalizedParameters');
    }
  }

  /// Returns events matching the given name
  List<Map<String, Object?>> getEventsByName(String name) {
    return _records
        .where((record) => record.name == name)
        .map((record) => record.toMap())
        .toList();
  }

  /// Returns count of events with the given name
  int getEventCount(String name) {
    return _records.where((record) => record.name == name).length;
  }

  /// Clears all recorded events
  void clear() {
    _records.clear();
  }

  /// Returns total number of logged events
  int get totalEvents => _records.length;

  /// Returns the most recently logged event or null if no events have been
  /// recorded. Useful in tests.
  RecordedAnalyticsEvent? get last => _records.isEmpty ? null : _records.last;

  /// Returns the most recent event name or null.
  String? get lastEventName => last?.name;

  /// Registers a mock capability for testing/demo purposes.
  void registerCapability<T extends AnalyticsCapability>(
    CapabilityKey<T> key,
    T capability,
  ) {
    _capabilities.register(key, capability);
  }

  @override
  AnalyticsCapabilityResolver get capabilityResolver => _capabilities;
}
