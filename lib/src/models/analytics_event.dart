/// Represents a single analytics event parameter.
final class AnalyticsParameter {
  final String name;
  final String type;
  final bool isNullable;
  final String? description;
  final List<String>? allowedValues;

  const AnalyticsParameter({
    required this.name,
    required this.type,
    required this.isNullable,
    this.description,
    this.allowedValues,
  });

  @override
  String toString() => '$name: $type${isNullable ? '?' : ''}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalyticsParameter &&
        other.name == name &&
        other.type == type &&
        other.isNullable == isNullable &&
        other.description == description &&
        _listEquals(other.allowedValues ?? const [], allowedValues ?? const []);
  }

  @override
  int get hashCode =>
      name.hashCode ^
      type.hashCode ^
      isNullable.hashCode ^
      description.hashCode ^
      Object.hashAll(allowedValues ?? const []);
}

/// Represents a single analytics event.
final class AnalyticsEvent {
  final String name;
  final String description;
  final String? customEventName;
  final List<AnalyticsParameter> parameters;
  final bool deprecated;
  final String? replacement;

  const AnalyticsEvent({
    required this.name,
    required this.description,
    this.customEventName,
    required this.parameters,
    this.deprecated = false,
    this.replacement,
  });

  @override
  String toString() => '$name (${parameters.length} parameters)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalyticsEvent &&
        other.name == name &&
        other.description == description &&
        other.customEventName == customEventName &&
        other.deprecated == deprecated &&
        other.replacement == replacement &&
        _listEquals(other.parameters, parameters);
  }

  @override
  int get hashCode =>
      name.hashCode ^
      description.hashCode ^
      customEventName.hashCode ^
      deprecated.hashCode ^
      replacement.hashCode ^
      Object.hashAll(parameters);
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalyticsDomain &&
        other.name == name &&
        _listEquals(other.events, events);
  }

  @override
  int get hashCode => name.hashCode ^ Object.hashAll(events);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
