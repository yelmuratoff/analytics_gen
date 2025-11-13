import '../core/analytics_interface.dart';

/// Mock analytics service for testing and development.
///
/// Records events in memory and provides query methods for verification.
final class MockAnalyticsService implements IAnalytics {
  /// All logged events, stored as maps with 'name' and 'parameters' keys
  final List<Map<String, dynamic>> events = [];

  /// Whether to print events to console when logged
  final bool verbose;

  MockAnalyticsService({this.verbose = false});

  @override
  void logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) {
    final event = {
      'name': name,
      'parameters': parameters ?? const <String, dynamic>{},
      'timestamp': DateTime.now().toIso8601String(),
    };

    events.add(event);

    if (verbose) {
      print('[Analytics] $name ${parameters ?? ''}');
    }
  }

  /// Returns events matching the given name
  List<Map<String, dynamic>> getEventsByName(String name) {
    return events.where((e) => e['name'] == name).toList();
  }

  /// Returns count of events with the given name
  int getEventCount(String name) {
    return events.where((e) => e['name'] == name).length;
  }

  /// Clears all recorded events
  void clear() {
    events.clear();
  }

  /// Returns total number of logged events
  int get totalEvents => events.length;
}
