/// Represents a single analytics event parameter.
final class AnalyticsParameter {
  final String name;
  final String type;
  final bool isNullable;
  final String? description;

  const AnalyticsParameter({
    required this.name,
    required this.type,
    required this.isNullable,
    this.description,
  });

  @override
  String toString() => '$name: $type${isNullable ? '?' : ''}';
}

/// Represents a single analytics event.
final class AnalyticsEvent {
  final String name;
  final String description;
  final String? customEventName;
  final List<AnalyticsParameter> parameters;

  const AnalyticsEvent({
    required this.name,
    required this.description,
    this.customEventName,
    required this.parameters,
  });

  @override
  String toString() => '$name (${parameters.length} parameters)';
}

/// Represents an analytics domain containing multiple events.
final class AnalyticsDomain {
  final String name;
  final List<AnalyticsEvent> events;

  const AnalyticsDomain({
    required this.name,
    required this.events,
  });

  int get eventCount => events.length;

  int get parameterCount =>
      events.fold(0, (sum, event) => sum + event.parameters.length);

  @override
  String toString() => '$name ($eventCount events, $parameterCount parameters)';
}
