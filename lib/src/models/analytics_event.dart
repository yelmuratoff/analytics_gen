import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import '../models/analytics_parameter.dart';

/// Represents a single analytics event.
@immutable
final class AnalyticsEvent {
  /// Parses an event from a YAML node.

  /// Creates a new analytics event from a map.
  factory AnalyticsEvent.fromMap(Map<String, dynamic> map) {
    T cast<T>(String k) => map[k] is T
        ? map[k] as T
        : throw ArgumentError.value(map[k], k, '$T ← ${map[k].runtimeType}');
    return AnalyticsEvent(
      name: cast<String?>('name') ?? '',
      description: cast<String?>('description') ?? '',
      identifier: cast<String?>('identifier'),
      customEventName: cast<String?>('custom_event_name'),
      parameters: List<AnalyticsParameter>.from(cast<Iterable?>('parameters')
              ?.map((x) => AnalyticsParameter.fromMap(Map.from(x as Map))) ??
          const <AnalyticsParameter>[]),
      deprecated: cast<bool?>('deprecated') ?? false,
      replacement: cast<String?>('replacement'),
      meta: Map<String, dynamic>.from(cast<Map?>('meta') ?? const {}),
      sourcePath: cast<String?>('source_path'),
      lineNumber: cast<num?>('line_number')?.toInt(),
      addedIn: cast<String?>('added_in'),
      deprecatedIn: cast<String?>('deprecated_in'),
      dualWriteTo: map['dual_write_to'] != null
          ? List<String>.from(cast<Iterable>('dual_write_to'))
          : null,
    );
  }

  /// Creates a new analytics event from a JSON string.
  factory AnalyticsEvent.fromJson(String source) =>
      AnalyticsEvent.fromMap(json.decode(source) as Map<String, dynamic>);

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
    this.addedIn,
    this.deprecatedIn,
    this.dualWriteTo,
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
  final Map<String, dynamic> meta;

  /// The path to the file where this event is defined.
  final String? sourcePath;

  /// The line number where this event is defined (1-based).
  final int? lineNumber;

  /// Version when this event was added.
  final String? addedIn;

  /// Version when this event was deprecated.
  final String? deprecatedIn;

  /// List of other events to trigger when this event is logged (dual-write).
  final List<String>? dualWriteTo;

  @override
  String toString() => '$name (${parameters.length} parameters)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final collectionEquals = const DeepCollectionEquality().equals;

    return other is AnalyticsEvent &&
        other.name == name &&
        other.description == description &&
        other.identifier == identifier &&
        other.customEventName == customEventName &&
        collectionEquals(other.parameters, parameters) &&
        other.deprecated == deprecated &&
        other.replacement == replacement &&
        collectionEquals(other.meta, meta) &&
        other.sourcePath == sourcePath &&
        other.lineNumber == lineNumber &&
        other.addedIn == addedIn &&
        other.deprecatedIn == deprecatedIn &&
        collectionEquals(other.dualWriteTo, dualWriteTo);
  }

  @override
  int get hashCode {
    final deepHash = const DeepCollectionEquality().hash;

    return Object.hashAll([
      name,
      description,
      identifier,
      customEventName,
      deepHash(parameters),
      deprecated,
      replacement,
      deepHash(meta),
      sourcePath,
      lineNumber,
      addedIn,
      deprecatedIn,
      deepHash(dualWriteTo),
    ]);
  }

  /// Creates a copy of this analytics event with the specified properties changed.
  AnalyticsEvent copyWith({
    String? name,
    String? description,
    String? identifier,
    String? customEventName,
    List<AnalyticsParameter>? parameters,
    bool? deprecated,
    String? replacement,
    Map<String, dynamic>? meta,
    String? sourcePath,
    int? lineNumber,
    String? addedIn,
    String? deprecatedIn,
    List<String>? dualWriteTo,
  }) {
    return AnalyticsEvent(
      name: name ?? this.name,
      description: description ?? this.description,
      identifier: identifier ?? this.identifier,
      customEventName: customEventName ?? this.customEventName,
      parameters: parameters ?? this.parameters,
      deprecated: deprecated ?? this.deprecated,
      replacement: replacement ?? this.replacement,
      meta: meta ?? this.meta,
      sourcePath: sourcePath ?? this.sourcePath,
      lineNumber: lineNumber ?? this.lineNumber,
      addedIn: addedIn ?? this.addedIn,
      deprecatedIn: deprecatedIn ?? this.deprecatedIn,
      dualWriteTo: dualWriteTo ?? this.dualWriteTo,
    );
  }

  /// Converts this analytics event to a map.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'identifier': identifier,
      'custom_event_name': customEventName,
      'parameters': parameters.map((x) => x.toMap()).toList(),
      'deprecated': deprecated,
      'replacement': replacement,
      'meta': meta,
      'source_path': sourcePath,
      'line_number': lineNumber,
      'added_in': addedIn,
      'deprecated_in': deprecatedIn,
      'dual_write_to': dualWriteTo,
    };
  }

  /// Converts this analytics event to a JSON string.
  String toJson() => json.encode(toMap());
}
