import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import '../config/naming_strategy.dart';
import '../core/exceptions.dart';
import '../models/analytics_event.dart';
import '../models/analytics_parameter.dart';

/// Represents an analytics domain containing multiple events.
@immutable
final class AnalyticsDomain {
  /// Parses a domain from a YAML node.
  factory AnalyticsDomain.fromYaml(
    String domainName,
    YamlNode valueNode, {
    required String filePath,
    required NamingStrategy naming,
    Map<String, AnalyticsParameter> sharedParameters = const {},
    bool enforceCentrallyDefinedParameters = false,
    bool preventEventParameterDuplicates = false,
    bool strictEventNames = true,
    void Function(AnalyticsParseException)? onError,
  }) {
    if (valueNode is! YamlMap) {
      throw AnalyticsParseException(
        'Domain "$domainName" must be a map of events.',
        filePath: filePath,
        span: valueNode.span,
      );
    }

    final eventsYaml = valueNode;
    final events = <AnalyticsEvent>[];

    final sortedEvents = eventsYaml.nodes.entries.toList()
      ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));

    for (final entry in sortedEvents) {
      final keyNode = entry.key as YamlNode;
      final eventName = keyNode.toString();
      final eventValue = entry.value;

      try {
        final event = AnalyticsEvent.fromYaml(
          eventName,
          eventValue,
          domainName: domainName,
          filePath: filePath,
          naming: naming,
          sharedParameters: sharedParameters,
          enforceCentrallyDefinedParameters: enforceCentrallyDefinedParameters,
          preventEventParameterDuplicates: preventEventParameterDuplicates,
          strictEventNames: strictEventNames,
          keySpan: keyNode.span,
        );
        events.add(event);
      } on AnalyticsParseException catch (e) {
        if (onError != null) {
          onError(e);
        } else {
          rethrow;
        }
      } catch (e) {
        final error = AnalyticsParseException(
          e.toString(),
          filePath: filePath,
          innerError: e,
          span: keyNode.span,
        );
        if (onError != null) {
          onError(error);
        } else {
          throw error;
        }
      }
    }

    return AnalyticsDomain(
      name: domainName,
      events: events,
    );
  }

  /// Creates a new analytics domain from a map.
  factory AnalyticsDomain.fromMap(Map<String, dynamic> map) {
    T cast<T>(String k) => map[k] is T
        ? map[k] as T
        : throw ArgumentError.value(map[k], k, '$T ← ${map[k].runtimeType}');
    return AnalyticsDomain(
      name: cast<String?>('name') ?? '',
      events: List<AnalyticsEvent>.from(cast<Iterable?>('events')
              ?.map((x) => AnalyticsEvent.fromMap(Map.from(x as Map))) ??
          const <AnalyticsEvent>[]),
    );
  }

  /// Creates a new analytics domain from a JSON string.
  factory AnalyticsDomain.fromJson(String source) =>
      AnalyticsDomain.fromMap(json.decode(source) as Map<String, dynamic>);

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

  /// Converts this analytics domain to a map.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'events': events.map((x) => x.toMap()).toList(),
    };
  }

  /// Converts this analytics domain to a JSON string.
  String toJson() => json.encode(toMap());
}
