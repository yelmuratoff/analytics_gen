import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';
import 'package:analytics_gen/src/models/serialization.dart';

import '../../config/naming_strategy.dart';
import '../../util/event_naming.dart';
import '../output_manager.dart';

/// Generates Excel-compatible CSV export of analytics events.
final class CsvGenerator {
  /// Creates a new CSV generator.
  CsvGenerator({
    required this.naming,
    this.outputManager = const OutputManager(),
  });

  /// The naming strategy to use.
  final NamingStrategy naming;

  /// The output manager to use.
  final OutputManager outputManager;

  /// Generates CSV files from analytics domains
  Future<void> generate(
    Map<String, AnalyticsDomain> domains,
    String outputDir,
  ) async {
    await _generateEventsCsv(domains, '$outputDir/analytics_events.csv');
    await _generateParametersCsv(
        domains, '$outputDir/analytics_parameters.csv');
    await _generateMetadataCsv(domains, '$outputDir/analytics_metadata.csv');
    await _generateEventParametersCsv(
        domains, '$outputDir/analytics_event_parameters.csv');
    await _generateMasterCsv(domains, '$outputDir/analytics_master.csv');
    await _generateDomainsCsv(domains, '$outputDir/analytics_domains.csv');
  }

  Future<void> _generateEventsCsv(
    Map<String, AnalyticsDomain> domains,
    String outputPath,
  ) async {
    final rows = <Map<String, dynamic>>[];

    for (final domain in domains.values) {
      for (final event in domain.events) {
        final row = AnalyticsSerialization.eventToMap(event);
        // Add computed/context fields
        row['domain'] = domain.name;
        row['event_name'] =
            EventNaming.resolveEventName(domain.name, event, naming);

        // Flatten meta
        if (row['meta'] is Map) {
          final meta = row['meta'] as Map;
          row['meta'] =
              meta.entries.map((e) => '${e.key}=${e.value}').join('; ');
        }

        // Remove complex fields not suitable for flat CSV (like parameters list)
        row.remove('parameters');
        row.remove('dual_write_to'); // or flatten it?
        row.remove('source_path'); // Internal field

        // Flatten dual_write_to if present
        if (event.dualWriteTo != null && event.dualWriteTo!.isNotEmpty) {
          row['dual_write_to'] = event.dualWriteTo!.join(';');
        }

        rows.add(row);
      }
    }

    await _writeCsv(outputPath, rows);
  }

  Future<void> _generateParametersCsv(
    Map<String, AnalyticsDomain> domains,
    String outputPath,
  ) async {
    final uniqueParams = <String, AnalyticsParameter>{};
    for (final domain in domains.values) {
      for (final event in domain.events) {
        for (final param in event.parameters) {
          if (!uniqueParams.containsKey(param.name)) {
            uniqueParams[param.name] = param;
          }
        }
      }
    }

    final rows = <Map<String, dynamic>>[];
    for (final param in uniqueParams.values) {
      final row = AnalyticsSerialization.parameterToMap(param);
      row.remove('source_path'); // Internal field

      // Flatten complex fields
      if (row['allowed_values'] is List) {
        row['allowed_values'] = (row['allowed_values'] as List).join('|');
      }
      if (row['meta'] is Map) {
        final meta = row['meta'] as Map;
        row['meta'] = meta.entries.map((e) => '${e.key}=${e.value}').join(';');
      }
      if (row['operations'] is List) {
        row['operations'] = (row['operations'] as List).join(';');
      }

      // Add validation summary column for convenience (optional, but good for backward compat/readability)
      final validation = <String>[];
      if (param.regex != null) validation.add('regex:${param.regex}');
      if (param.minLength != null) validation.add('min_len:${param.minLength}');
      if (param.maxLength != null) validation.add('max_len:${param.maxLength}');
      if (param.min != null) validation.add('min:${param.min}');
      if (param.max != null) validation.add('max:${param.max}');
      row['validation'] = validation.join(';');

      rows.add(row);
    }

    await _writeCsv(outputPath, rows);
  }

  Future<void> _generateMetadataCsv(
    Map<String, AnalyticsDomain> domains,
    String outputPath,
  ) async {
    // Metadata CSV structure is specific (Type, Name, Key, Value), not a direct map dump.
    // Keeping existing logic but using toMap where appropriate if needed,
    // but the existing logic is already quite specific and correct for this format.
    // I will keep it mostly as is but ensure it uses the resolved names correctly.

    final buffer = StringBuffer();
    buffer.writeln('Type,Name,Key,Value');

    for (final domain in domains.values) {
      for (final event in domain.events) {
        final eventName =
            EventNaming.resolveEventName(domain.name, event, naming);
        for (final entry in event.meta.entries) {
          buffer.writeln(
            'Event,${_escape(eventName)},${_escape(entry.key)},${_escape(entry.value.toString())}',
          );
        }
        for (final param in event.parameters) {
          for (final entry in param.meta.entries) {
            buffer.writeln(
              'Parameter,${_escape(param.name)},${_escape(entry.key)},${_escape(entry.value.toString())}',
            );
          }
        }
      }
    }
    await outputManager.writeFileIfContentChanged(
        outputPath, buffer.toString());
  }

  Future<void> _generateEventParametersCsv(
    Map<String, AnalyticsDomain> domains,
    String outputPath,
  ) async {
    // This is also a specific format: Event Name, Parameter Name, Required.
    // Keeping as is.
    final buffer = StringBuffer();
    buffer.writeln('Event Name,Parameter Name,Required');

    for (final domain in domains.values) {
      for (final event in domain.events) {
        final eventName =
            EventNaming.resolveEventName(domain.name, event, naming);
        for (final param in event.parameters) {
          buffer.writeln(
            '${_escape(eventName)},${_escape(param.name)},${!param.isNullable}',
          );
        }
      }
    }
    await outputManager.writeFileIfContentChanged(
        outputPath, buffer.toString());
  }

  Future<void> _generateMasterCsv(
    Map<String, AnalyticsDomain> domains,
    String outputPath,
  ) async {
    final rows = <Map<String, dynamic>>[];

    for (final domain in domains.values) {
      for (final event in domain.events) {
        final eventRow = AnalyticsSerialization.eventToMap(event);
        eventRow['domain'] = domain.name;
        eventRow['event_name'] =
            EventNaming.resolveEventName(domain.name, event, naming);

        // Flatten event meta
        if (eventRow['meta'] is Map) {
          eventRow['meta'] = (eventRow['meta'] as Map)
              .entries
              .map((e) => '${e.key}=${e.value}')
              .join('; ');
        }
        eventRow.remove('parameters'); // Handled below
        eventRow.remove('dual_write_to');
        eventRow.remove('source_path'); // Internal field
        if (event.dualWriteTo != null) {
          eventRow['dual_write_to'] = event.dualWriteTo!.join(';');
        }

        // Prefix event keys to avoid collision with parameter keys
        // Exception: 'domain' and 'event_name' are fine as is or can be prefixed.
        // Let's keep 'domain' as is, and 'event_name' is already specific.
        // But 'name', 'description' etc should be prefixed.

        final finalEventRow = <String, dynamic>{};
        finalEventRow['domain'] = domain.name;
        finalEventRow['event_name'] = eventRow['event_name'];

        eventRow.forEach((k, v) {
          if (k != 'domain' && k != 'event_name') {
            finalEventRow['event_$k'] = v;
          }
        });

        if (event.parameters.isEmpty) {
          rows.add(finalEventRow);
        } else {
          for (final param in event.parameters) {
            final paramRow = AnalyticsSerialization.parameterToMap(param);
            paramRow.remove('source_path'); // Internal field
            final combinedRow = Map<String, dynamic>.from(finalEventRow);

            // Flatten param fields
            if (paramRow['allowed_values'] is List) {
              paramRow['allowed_values'] =
                  (paramRow['allowed_values'] as List).join('|');
            }
            if (paramRow['meta'] is Map) {
              paramRow['meta'] = (paramRow['meta'] as Map)
                  .entries
                  .map((e) => '${e.key}=${e.value}')
                  .join(';');
            }
            if (paramRow['operations'] is List) {
              paramRow['operations'] =
                  (paramRow['operations'] as List).join(';');
            }
            // Add validation summary
            final validation = <String>[];
            if (param.regex != null) validation.add('regex:${param.regex}');
            if (param.minLength != null) {
              validation.add('min_len:${param.minLength}');
            }
            if (param.maxLength != null) {
              validation.add('max_len:${param.maxLength}');
            }
            if (param.min != null) validation.add('min:${param.min}');
            if (param.max != null) validation.add('max:${param.max}');
            paramRow['validation'] = validation.join(';');

            // Prefix parameter keys
            paramRow.forEach((k, v) {
              combinedRow['parameter_$k'] = v;
            });

            rows.add(combinedRow);
          }
        }
      }
    }

    await _writeCsv(outputPath, rows);
  }

  Future<void> _generateDomainsCsv(
    Map<String, AnalyticsDomain> domains,
    String outputPath,
  ) async {
    final rows = <Map<String, dynamic>>[];
    for (final domain in domains.values) {
      rows.add(AnalyticsSerialization.domainToMap(domain));
    }
    // domain.toMap() has 'name' and 'events'. We want counts.
    // Domain.toMap doesn't have counts.
    // We should add them.
    for (final row in rows) {
      final domainName = row['name'] as String;
      final domain = domains[domainName]!;
      row['event_count'] = domain.eventCount;
      row['parameter_count'] = domain.parameterCount;
      row.remove('events'); // Remove list of events
    }
    await _writeCsv(outputPath, rows);
  }

  /// Generic helper to write a list of maps to a CSV file.
  /// Dynamically determines headers from all keys present in the rows.
  Future<void> _writeCsv(
      String outputPath, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) {
      await outputManager.writeFileIfContentChanged(outputPath, '');
      return;
    }

    // Collect all unique keys to form headers
    final headers = <String>{};
    for (final row in rows) {
      headers.addAll(row.keys);
    }

    // Sort headers for deterministic output (optional but good)
    // We might want specific headers first (like domain, event_name).
    final sortedHeaders = headers.toList()
      ..sort((a, b) {
        // Prioritize common ID fields
        final scoreA = _headerScore(a);
        final scoreB = _headerScore(b);
        if (scoreA != scoreB) return scoreA.compareTo(scoreB);
        return a.compareTo(b);
      });

    final buffer = StringBuffer();
    // Write header row
    buffer.writeln(sortedHeaders.map(_escape).join(','));

    // Write data rows
    for (final row in rows) {
      final line = sortedHeaders.map((header) {
        final value = row[header];
        return _escape(value?.toString() ?? '');
      }).join(',');
      buffer.writeln(line);
    }

    await outputManager.writeFileIfContentChanged(
        outputPath, buffer.toString());
  }

  int _headerScore(String header) {
    switch (header) {
      case 'domain':
        return 0;
      case 'event_name':
        return 1;
      case 'name':
        return 2;
      case 'type':
        return 3;
      case 'description':
        return 4;
      default:
        return 100;
    }
  }

  /// Escapes CSV values
  String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
