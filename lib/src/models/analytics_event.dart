import 'package:collection/collection.dart';

const _listEq = ListEquality<String>();

/// Represents a single analytics event parameter.
final class AnalyticsParameter {
  /// Analytics key that gets sent to providers.
  final String name;

  /// Identifier used when generating Dart API (defaults to [name]).
  final String codeName;

  final String type;
  final bool isNullable;
  final String? description;
  final List<String>? allowedValues;

  const AnalyticsParameter({
    required this.name,
    String? codeName,
    required this.type,
    required this.isNullable,
    this.description,
    this.allowedValues,
  }) : codeName = codeName ?? name;

  @override
  String toString() => '$name: $type${isNullable ? '?' : ''}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalyticsParameter &&
        other.name == name &&
        other.codeName == codeName &&
        other.type == type &&
        other.isNullable == isNullable &&
        other.description == description &&
        _listEq.equals(other.allowedValues, allowedValues);
  }

  @override
  int get hashCode => Object.hash(
        name,
        codeName,
        type,
        isNullable,
        description,
        _listEq.hash(allowedValues ?? const []),
      );
}

const _paramListEq = ListEquality<AnalyticsParameter>();

/// Represents a single analytics event.
final class AnalyticsEvent {
  final String name;
  final String description;
  final String? identifier;
  final String? customEventName;
  final List<AnalyticsParameter> parameters;
  final bool deprecated;
  final String? replacement;

  const AnalyticsEvent({
    required this.name,
    required this.description,
    this.identifier,
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
        other.identifier == identifier &&
        other.customEventName == customEventName &&
        other.deprecated == deprecated &&
        other.replacement == replacement &&
        _paramListEq.equals(other.parameters, parameters);
  }

  @override
  int get hashCode => Object.hash(
        name,
        description,
        identifier,
        customEventName,
        deprecated,
        replacement,
        _paramListEq.hash(parameters),
      );
}

const _eventListEq = ListEquality<AnalyticsEvent>();

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
        _eventListEq.equals(other.events, events);
  }

  @override
  int get hashCode => Object.hash(name, _eventListEq.hash(events));
}
