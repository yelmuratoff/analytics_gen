import 'dart:convert';

import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';

import 'package:meta/meta.dart';

/// Serialization helpers for analytics models.
///
/// Keeps domain entities pure by separating parsing/serialization logic.
@immutable
final class AnalyticsSerialization {
  const AnalyticsSerialization._();

  // --- Domain ---

  /// Creates a new analytics domain from a map.
  static AnalyticsDomain domainFromMap(Map<String, dynamic> map) {
    T cast<T>(String k) => map[k] is T
        ? map[k] as T
        : throw ArgumentError.value(map[k], k, '$T ← ${map[k].runtimeType}');

    return AnalyticsDomain(
      name: cast<String?>('name') ?? '',
      events: List<AnalyticsEvent>.from(cast<Iterable?>('events')?.map(
              (x) => AnalyticsSerialization.eventFromMap(Map.from(x as Map))) ??
          const <AnalyticsEvent>[]),
    );
  }

  /// Converts a domain to a map.
  static Map<String, dynamic> domainToMap(AnalyticsDomain domain) {
    return {
      'name': domain.name,
      'events': domain.events.map(eventToMap).toList(),
    };
  }

  /// Converts a domain to JSON.
  static String domainToJson(AnalyticsDomain domain) =>
      json.encode(domainToMap(domain));

  // --- Event ---

  /// Creates a new analytics event from a map.
  static AnalyticsEvent eventFromMap(Map<String, dynamic> map) {
    T cast<T>(String k) => map[k] is T
        ? map[k] as T
        : throw ArgumentError.value(map[k], k, '$T ← ${map[k].runtimeType}');

    return AnalyticsEvent(
      name: cast<String?>('name') ?? '',
      description: cast<String?>('description') ?? '',
      identifier: cast<String?>('identifier'),
      customEventName: cast<String?>('custom_event_name'),
      parameters: List<AnalyticsParameter>.from(cast<Iterable?>('parameters')
              ?.map((x) => AnalyticsSerialization.parameterFromMap(
                  Map.from(x as Map))) ??
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
      interpolatedName: cast<String?>(
          'interpolated_name'), // Note: this might be missing in older serialized versions?
    );
  }

  /// Converts an event to a map.
  static Map<String, dynamic> eventToMap(AnalyticsEvent event) {
    return {
      'name': event.name,
      'description': event.description,
      'identifier': event.identifier,
      'custom_event_name': event.customEventName,
      'parameters': event.parameters.map(parameterToMap).toList(),
      'deprecated': event.deprecated,
      'replacement': event.replacement,
      'meta': event.meta,
      'source_path': event.sourcePath,
      'line_number': event.lineNumber,
      'added_in': event.addedIn,
      'deprecated_in': event.deprecatedIn,
      'dual_write_to': event.dualWriteTo,
      'interpolated_name': event.interpolatedName,
    };
  }

  /// Converts an event to JSON.
  static String eventToJson(AnalyticsEvent event) =>
      json.encode(eventToMap(event));

  // --- Parameter ---

  /// Creates a new analytics parameter from a map.
  static AnalyticsParameter parameterFromMap(Map<String, dynamic> map) {
    T cast<T>(String k) => map[k] is T
        ? map[k] as T
        : throw ArgumentError.value(map[k], k, '$T ← ${map[k].runtimeType}');

    return AnalyticsParameter(
      name: cast<String?>('name') ?? '',
      sourceName: cast<String?>('source_name'),
      codeName: cast<String?>('code_name') ?? '',
      type: cast<String?>('type') ?? '',
      dartType: map['dart_type'] as String?,
      dartImport: map['dart_import'] as String?,
      isNullable: cast<bool?>('is_nullable') ?? false,
      description: cast<String?>('description'),
      allowedValues: map['allowed_values'] != null
          ? List<Object>.from(cast<Iterable>('allowed_values'))
          : null,
      regex: cast<String?>('regex'),
      minLength: cast<num?>('min_length')?.toInt(),
      maxLength: cast<num?>('max_length')?.toInt(),
      min: cast<num?>('min'),
      max: cast<num?>('max'),
      meta: Map<String, dynamic>.from(cast<Map?>('meta') ?? const {}),
      operations: map['operations'] != null
          ? List<String>.from(cast<Iterable>('operations'))
          : const [],
      addedIn: cast<String?>('added_in'),
      deprecatedIn: cast<String?>('deprecated_in'),
    );
  }

  /// Converts a parameter to a map.
  static Map<String, dynamic> parameterToMap(AnalyticsParameter param) {
    return {
      'name': param.name,
      'source_name': param.sourceName,
      'code_name': param.codeName,
      'type': param.type,
      'dart_type': param.dartType,
      'dart_import': param.dartImport,
      'is_nullable': param.isNullable,
      'description': param.description,
      'allowed_values': param.allowedValues,
      'regex': param.regex,
      'min_length': param.minLength,
      'max_length': param.maxLength,
      'min': param.min,
      'max': param.max,
      'meta': param.meta,
      'operations': param.operations,
      'added_in': param.addedIn,
      'deprecated_in': param.deprecatedIn,
    };
  }
}
