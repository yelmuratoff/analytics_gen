import 'package:collection/collection.dart';

import '../core/analytics_interface.dart';

const _mapEq = MapEquality<String, Object?>();

/// Immutable snapshot of an analytics event recorded by [MockAnalyticsService].
final class RecordedAnalyticsEvent {
  /// Creates a new recorded event.
  RecordedAnalyticsEvent({
    required this.name,
    required AnalyticsParams parameters,
    required this.timestamp,
  }) : parameters = Map.unmodifiable(parameters);

  /// Name of the logged event (e.g., `auth: login` or a custom `event_name`).
  final String name;

  /// Parameters captured when the event was logged.
  final AnalyticsParams parameters;

  /// Timestamp captured when the event was logged.
  final DateTime timestamp;

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
        _mapEq.equals(other.parameters, parameters);
  }

  @override
  int get hashCode => Object.hash(name, timestamp, _mapEq.hash(parameters));
}
