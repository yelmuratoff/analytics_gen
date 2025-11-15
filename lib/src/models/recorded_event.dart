import '../core/analytics_interface.dart';

/// Immutable snapshot of an analytics event recorded by [MockAnalyticsService].
final class RecordedAnalyticsEvent {
  /// Name of the logged event (e.g., `auth: login` or a custom `event_name`).
  final String name;

  /// Parameters captured when the event was logged.
  final AnalyticsParams parameters;

  /// Timestamp captured when the event was logged.
  final DateTime timestamp;

  RecordedAnalyticsEvent({
    required this.name,
    required AnalyticsParams parameters,
    required this.timestamp,
  }) : parameters = Map.unmodifiable(parameters);

  /// Returns a JSON-friendly map identical to the legacy [MockAnalyticsService.events] entries.
  Map<String, Object?> toMap() => {
        'name': name,
        'parameters': parameters,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecordedAnalyticsEvent &&
        other.name == name &&
        other.timestamp == timestamp &&
        _mapEquals(other.parameters, parameters);
  }

  @override
  int get hashCode =>
      name.hashCode ^ timestamp.hashCode ^ _mapHash(parameters);
}

bool _mapEquals(Map<String, Object?> a, Map<String, Object?> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key)) return false;
    final aValue = a[key];
    final bValue = b[key];
    if (aValue != bValue) return false;
  }
  return true;
}

int _mapHash(Map<String, Object?> map) {
  var hash = 0;
  final entries = map.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  for (final entry in entries) {
    hash = hash * 31 + entry.key.hashCode;
    hash = hash * 31 + (entry.value?.hashCode ?? 0);
  }

  return hash;
}
