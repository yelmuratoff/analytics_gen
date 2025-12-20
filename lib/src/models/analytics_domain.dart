import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import '../models/analytics_event.dart';

/// Represents an analytics domain containing multiple events.
@immutable
final class AnalyticsDomain {
  /// Creates a new analytics domain.
  const AnalyticsDomain({
    required this.name,
    required this.events,
  });

  /// The name of the domain.
  final String name;

  /// The list of events in this domain.
  final List<AnalyticsEvent> events;

  /// Returns the number of events in this domain.
  int get eventCount => events.length;

  /// Returns the total number of parameters across all events.
  int get parameterCount =>
      events.fold(0, (sum, event) => sum + event.parameters.length);

  @override
  String toString() => '$name ($eventCount events, $parameterCount parameters)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is AnalyticsDomain &&
        other.name == name &&
        listEquals(other.events, events);
  }

  @override
  int get hashCode {
    final deepHash = const DeepCollectionEquality().hash;
    return Object.hash(name, deepHash(events));
  }

  /// Creates a copy of this analytics domain with the specified properties changed.
  AnalyticsDomain copyWith({
    String? name,
    List<AnalyticsEvent>? events,
  }) {
    return AnalyticsDomain(
      name: name ?? this.name,
      events: events ?? this.events,
    );
  }
}
