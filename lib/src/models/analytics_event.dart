import 'package:collection/collection.dart';

const _listEq = ListEquality<Object>();
const _mapEq = MapEquality<String, Object?>();

/// Represents a single analytics event parameter.
final class AnalyticsParameter {
  /// Creates a new analytics parameter.
  const AnalyticsParameter({
    required this.name,
    String? codeName,
    required this.type,
    required this.isNullable,
    this.description,
    this.allowedValues,
    this.regex,
    this.minLength,
    this.maxLength,
    this.min,
    this.max,
    this.meta = const {},
  }) : codeName = codeName ?? name;

  /// Analytics key that gets sent to providers.
  final String name;

  /// Identifier used when generating Dart API (defaults to [name]).
  final String codeName;

  /// The Dart type of the parameter.
  final String type;

  /// Whether the parameter is nullable.
  final bool isNullable;

  /// Optional description of the parameter.
  final String? description;

  /// Optional list of allowed values.
  final List<Object>? allowedValues;

  // Validation rules
  /// Regex pattern for validation.
  final String? regex;

  /// Minimum length for string parameters.
  final int? minLength;

  /// Maximum length for string parameters.
  final int? maxLength;

  /// Minimum value for numeric parameters.
  final num? min;

  /// Maximum value for numeric parameters.
  final num? max;

  /// Custom metadata for this parameter (e.g. PII flags, ownership).
  final Map<String, Object?> meta;

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
        _listEq.equals(other.allowedValues, allowedValues) &&
        other.regex == regex &&
        other.minLength == minLength &&
        other.maxLength == maxLength &&
        other.min == min &&
        other.max == max &&
        _mapEq.equals(other.meta, meta);
  }

  @override
  int get hashCode => Object.hash(
        name,
        codeName,
        type,
        isNullable,
        description,
        _listEq.hash(allowedValues ?? const []),
        regex,
        minLength,
        maxLength,
        min,
        max,
        _mapEq.hash(meta),
      );
}

const _paramListEq = ListEquality<AnalyticsParameter>();

/// Represents a single analytics event.
final class AnalyticsEvent {
  /// Creates a new analytics event.
  const AnalyticsEvent({
    required this.name,
    required this.description,
    this.identifier,
    this.customEventName,
    required this.parameters,
    this.deprecated = false,
    this.replacement,
    this.meta = const {},
    this.sourcePath,
    this.lineNumber,
  });

  /// The name of the event.
  final String name;

  /// The description of the event.
  final String description;

  /// Optional unique identifier for the event.
  final String? identifier;

  /// Optional custom event name to be logged.
  final String? customEventName;

  /// The list of parameters for this event.
  final List<AnalyticsParameter> parameters;

  /// Whether this event is deprecated.
  final bool deprecated;

  /// Optional replacement event name if deprecated.
  final String? replacement;

  /// Custom metadata for this event (e.g. ownership, Jira tickets).
  final Map<String, Object?> meta;

  /// The path to the file where this event is defined.
  final String? sourcePath;

  /// The line number where this event is defined (1-based).
  final int? lineNumber;

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
        _paramListEq.equals(other.parameters, parameters) &&
        _mapEq.equals(other.meta, meta) &&
        other.sourcePath == sourcePath &&
        other.lineNumber == lineNumber;
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
        _mapEq.hash(meta),
        sourcePath,
        lineNumber,
      );
}

const _eventListEq = ListEquality<AnalyticsEvent>();

/// Represents an analytics domain containing multiple events.
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
    return other is AnalyticsDomain &&
        other.name == name &&
        _eventListEq.equals(other.events, events);
  }

  @override
  int get hashCode => Object.hash(name, _eventListEq.hash(events));
}
