import 'dart:convert';

import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';

import '../models/analytics_event.dart';

/// Represents a type of schema change.
enum SchemaChangeType {
  /// A domain, event, or parameter was added.
  added,

  /// A domain, event, or parameter was removed.
  removed,

  /// A domain, event, or parameter was modified.
  modified,
}

/// Represents a single change in the analytics schema.
class SchemaChange {
  /// Creates a new schema change.
  const SchemaChange({
    required this.type,
    required this.description,
    required this.path,
    this.isBreaking = false,
  });

  /// The type of change.
  final SchemaChangeType type;

  /// Description of the change.
  final String description;

  /// Path to the changed element (e.g. "auth.login.method").
  final String path;

  /// Whether this change is breaking.
  final bool isBreaking;

  @override
  String toString() =>
      '[${type.name.toUpperCase()}] $path: $description${isBreaking ? " (BREAKING)" : ""}';
}

/// Utility for comparing analytics schemas and detecting changes.
class SchemaComparator {
  /// Compares the current schema with a previous schema loaded from JSON.
  List<SchemaChange> compare(
    Map<String, AnalyticsDomain> current,
    Map<String, AnalyticsDomain> previous,
  ) {
    final changes = <SchemaChange>[];

    // Check for removed domains
    for (final domainName in previous.keys) {
      if (!current.containsKey(domainName)) {
        changes.add(SchemaChange(
          type: SchemaChangeType.removed,
          description: 'Domain "$domainName" was removed.',
          path: domainName,
          isBreaking: true,
        ));
      }
    }

    // Check for added or modified domains
    for (final domainName in current.keys) {
      final currentDomain = current[domainName]!;
      final previousDomain = previous[domainName];

      if (previousDomain == null) {
        changes.add(SchemaChange(
          type: SchemaChangeType.added,
          description: 'Domain "$domainName" was added.',
          path: domainName,
        ));
        continue;
      }

      changes.addAll(_compareDomains(currentDomain, previousDomain));
    }

    return changes;
  }

  List<SchemaChange> _compareDomains(
    AnalyticsDomain current,
    AnalyticsDomain previous,
  ) {
    final changes = <SchemaChange>[];
    final domainPath = current.name;

    final currentEvents = {for (final e in current.events) e.name: e};
    final previousEvents = {for (final e in previous.events) e.name: e};

    // Removed events
    for (final eventName in previousEvents.keys) {
      if (!currentEvents.containsKey(eventName)) {
        changes.add(SchemaChange(
          type: SchemaChangeType.removed,
          description: 'Event "$eventName" was removed.',
          path: '$domainPath.$eventName',
          isBreaking: true,
        ));
      }
    }

    // Added or modified events
    for (final eventName in currentEvents.keys) {
      final currentEvent = currentEvents[eventName]!;
      final previousEvent = previousEvents[eventName];

      if (previousEvent == null) {
        changes.add(SchemaChange(
          type: SchemaChangeType.added,
          description: 'Event "$eventName" was added.',
          path: '$domainPath.$eventName',
        ));
        continue;
      }

      changes.addAll(_compareEvents(currentEvent, previousEvent, domainPath));
    }

    return changes;
  }

  List<SchemaChange> _compareEvents(
    AnalyticsEvent current,
    AnalyticsEvent previous,
    String domainPath,
  ) {
    final changes = <SchemaChange>[];
    final eventPath = '$domainPath.${current.name}';

    // Check deprecation status change
    if (current.deprecated != previous.deprecated) {
      changes.add(SchemaChange(
        type: SchemaChangeType.modified,
        description: current.deprecated
            ? 'Event was deprecated.'
            : 'Event was un-deprecated.',
        path: eventPath,
        isBreaking: false,
      ));
    }

    // Dual-write changes
    final currentDualWrite = Set<String>.from(current.dualWriteTo ?? []);
    final previousDualWrite = Set<String>.from(previous.dualWriteTo ?? []);

    final removedDualWrites = previousDualWrite.difference(currentDualWrite);
    if (removedDualWrites.isNotEmpty) {
      changes.add(SchemaChange(
        type: SchemaChangeType.modified,
        description:
            'Dual-write targets removed: ${removedDualWrites.join(", ")}',
        path: eventPath,
        isBreaking: true,
      ));
    }

    final addedDualWrites = currentDualWrite.difference(previousDualWrite);
    if (addedDualWrites.isNotEmpty) {
      changes.add(SchemaChange(
        type: SchemaChangeType.modified,
        description: 'Dual-write targets added: ${addedDualWrites.join(", ")}',
        path: eventPath,
        isBreaking: false,
      ));
    }

    final currentParams = {for (final p in current.parameters) p.name: p};
    final previousParams = {for (final p in previous.parameters) p.name: p};

    // Removed parameters
    for (final paramName in previousParams.keys) {
      if (!currentParams.containsKey(paramName)) {
        changes.add(SchemaChange(
          type: SchemaChangeType.removed,
          description: 'Parameter "$paramName" was removed.',
          path: '$eventPath.$paramName',
          isBreaking: true,
        ));
      }
    }

    // Added or modified parameters
    for (final paramName in currentParams.keys) {
      final currentParam = currentParams[paramName]!;
      final previousParam = previousParams[paramName];

      if (previousParam == null) {
        // Adding a required parameter is breaking
        final isBreaking = !currentParam.isNullable;
        changes.add(SchemaChange(
          type: SchemaChangeType.added,
          description: 'Parameter "$paramName" was added.',
          path: '$eventPath.$paramName',
          isBreaking: isBreaking,
        ));
        continue;
      }

      changes
          .addAll(_compareParameters(currentParam, previousParam, eventPath));
    }

    return changes;
  }

  List<SchemaChange> _compareParameters(
    AnalyticsParameter current,
    AnalyticsParameter previous,
    String eventPath,
  ) {
    final changes = <SchemaChange>[];
    final paramPath = '$eventPath.${current.name}';

    // Type change
    if (current.type != previous.type) {
      changes.add(SchemaChange(
        type: SchemaChangeType.modified,
        description:
            'Type changed from "${previous.type}" to "${current.type}".',
        path: paramPath,
        isBreaking: true,
      ));
    }

    // Nullability change
    if (current.isNullable != previous.isNullable) {
      final isBreaking = !current.isNullable && previous.isNullable;
      changes.add(SchemaChange(
        type: SchemaChangeType.modified,
        description:
            'Nullability changed from ${previous.isNullable} to ${current.isNullable}.',
        path: paramPath,
        isBreaking: isBreaking,
      ));
    }

    // Validation changes (regex, min, max, etc.)
    // Adding validation is technically breaking for data ingestion (rejects previously valid data)
    // but maybe not for code compilation. We'll mark it as breaking for safety.
    if (current.regex != previous.regex) {
      changes.add(SchemaChange(
        type: SchemaChangeType.modified,
        description: 'Regex validation changed.',
        path: paramPath,
        isBreaking: true,
      ));
    }
    // ... other validations can be added similarly

    return changes;
  }

  /// Reconstructs domains from a JSON export string.
  static Map<String, AnalyticsDomain> loadSchemaFromJson(String jsonContent) {
    final json = jsonDecode(jsonContent) as Map<String, dynamic>;
    final domains = <String, AnalyticsDomain>{};

    final domainsList = json['domains'] as List<dynamic>? ?? [];
    for (final d in domainsList) {
      final domainMap = d as Map<String, dynamic>;
      final domainName = domainMap['name'] as String;
      final eventsList = domainMap['events'] as List<dynamic>? ?? [];

      final events = <AnalyticsEvent>[];
      for (final e in eventsList) {
        final eventMap = e as Map<String, dynamic>;
        final paramsList = eventMap['parameters'] as List<dynamic>? ?? [];

        final parameters = <AnalyticsParameter>[];
        for (final p in paramsList) {
          final paramMap = p as Map<String, dynamic>;
          parameters.add(AnalyticsParameter(
            name: paramMap['name'] as String,
            codeName: paramMap['code_name'] as String?,
            type: paramMap['type'] as String,
            isNullable: paramMap['nullable'] as bool? ?? false,
            description: paramMap['description'] as String?,
            allowedValues:
                (paramMap['allowed_values'] as List?)?.cast<Object>(),
            regex: paramMap['regex'] as String?,
            minLength: paramMap['min_length'] as int?,
            maxLength: paramMap['max_length'] as int?,
            min: paramMap['min'] as num?,
            max: paramMap['max'] as num?,
            addedIn: paramMap['added_in'] as String?,
            deprecatedIn: paramMap['deprecated_in'] as String?,
            meta:
                (paramMap['meta'] as Map?)?.cast<String, Object?>() ?? const {},
          ));
        }

        events.add(AnalyticsEvent(
          name: eventMap['name'] as String,
          description: eventMap['description'] as String? ?? '',
          identifier: eventMap['identifier'] as String?,
          customEventName: eventMap['event_name'] as String?,
          deprecated: eventMap['deprecated'] as bool? ?? false,
          replacement: eventMap['replacement'] as String?,
          addedIn: eventMap['added_in'] as String?,
          deprecatedIn: eventMap['deprecated_in'] as String?,
          dualWriteTo: (eventMap['dual_write_to'] as List?)?.cast<String>(),
          meta: (eventMap['meta'] as Map?)?.cast<String, Object?>() ?? const {},
          parameters: parameters,
        ));
      }

      domains[domainName] = AnalyticsDomain(
        name: domainName,
        events: events,
      );
    }

    return domains;
  }
}
