import '../core/analytics_interface.dart';
import '../models/recorded_event.dart';

/// Mock analytics service for testing and development.
///
/// Records events in memory and provides query methods for verification.
final class MockAnalyticsService implements IAnalytics {
  final List<RecordedAnalyticsEvent> _records = [];

  /// Whether to print events to console when logged
  final bool verbose;

  MockAnalyticsService({this.verbose = false});

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
      print('[Analytics] $name $normalizedParameters');
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
}
