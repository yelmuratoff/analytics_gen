import 'dart:convert';

import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';

import '../../config/naming_strategy.dart';
import '../../util/event_naming.dart';
import '../../util/file_utils.dart';
import '../generation_metadata.dart';

/// Generates SQL schema and data inserts for analytics events.
final class SqlGenerator {
  /// Creates a new SQL generator.
  SqlGenerator({required this.naming});

  /// The naming strategy to use.
  final NamingStrategy naming;

  /// Generates SQL file with schema and data
  Future<void> generate(
    Map<String, AnalyticsDomain> domains,
    String outputPath,
  ) async {
    final buffer = StringBuffer();

    final metadata = GenerationMetadata.fromDomains(domains);
    final sortedDomains = _sortedDomains(domains);

    _writeHeader(buffer, metadata);
    _writeSchema(buffer);
    _writeIndexes(buffer);
    _writeData(buffer, sortedDomains);
    _writeViews(buffer);

    await writeFileIfContentChanged(outputPath, buffer.toString());
  }

  void _writeHeader(StringBuffer buffer, GenerationMetadata metadata) {
    buffer.writeln('-- Analytics Events Database Schema');
    buffer.writeln(
      '-- Fingerprint: ${metadata.fingerprint} '
      '(domains=${metadata.totalDomains}, '
      'events=${metadata.totalEvents}, '
      'parameters=${metadata.totalParameters})',
    );
    buffer.writeln();
  }

  void _writeSchema(StringBuffer buffer) {
    buffer.writeln('-- Create domains table');
    buffer.writeln('CREATE TABLE IF NOT EXISTS domains (');
    buffer.writeln('  id INTEGER PRIMARY KEY AUTOINCREMENT,');
    buffer.writeln('  name TEXT NOT NULL UNIQUE,');
    buffer.writeln('  event_count INTEGER NOT NULL,');
    buffer.writeln('  parameter_count INTEGER NOT NULL');
    buffer.writeln(');');
    buffer.writeln();

    buffer.writeln('-- Create events table');
    buffer.writeln('CREATE TABLE IF NOT EXISTS events (');
    buffer.writeln('  id INTEGER PRIMARY KEY AUTOINCREMENT,');
    buffer.writeln('  domain_id INTEGER NOT NULL,');
    buffer.writeln('  name TEXT NOT NULL,');
    buffer.writeln('  event_name TEXT NOT NULL,');
    buffer.writeln('  identifier TEXT NOT NULL,');
    buffer.writeln('  description TEXT NOT NULL,');
    buffer.writeln('  deprecated INTEGER NOT NULL DEFAULT 0,');
    buffer.writeln('  replacement TEXT,');
    buffer.writeln('  added_in TEXT,');
    buffer.writeln('  deprecated_in TEXT,');
    buffer.writeln('  custom_event_name TEXT,');
    buffer.writeln('  dual_write_to TEXT,');
    buffer.writeln('  meta TEXT,');
    buffer.writeln('  source_path TEXT,');
    buffer.writeln('  line_number INTEGER,');
    buffer.writeln('  FOREIGN KEY (domain_id) REFERENCES domains(id),');
    buffer.writeln('  UNIQUE(domain_id, name)');
    buffer.writeln(');');
    buffer.writeln();

    buffer.writeln('-- Create parameters table');
    buffer.writeln('CREATE TABLE IF NOT EXISTS parameters (');
    buffer.writeln('  id INTEGER PRIMARY KEY AUTOINCREMENT,');
    buffer.writeln('  event_id INTEGER NOT NULL,');
    buffer.writeln('  name TEXT NOT NULL,');
    buffer.writeln('  source_name TEXT,');
    buffer.writeln('  code_name TEXT NOT NULL,');
    buffer.writeln('  type TEXT NOT NULL,');
    buffer.writeln('  nullable INTEGER NOT NULL,');
    buffer.writeln('  description TEXT,');
    buffer.writeln('  allowed_values TEXT,');
    buffer.writeln('  regex TEXT,');
    buffer.writeln('  min_length INTEGER,');
    buffer.writeln('  max_length INTEGER,');
    buffer.writeln('  min REAL,');
    buffer.writeln('  max REAL,');
    buffer.writeln('  operations TEXT,');
    buffer.writeln('  added_in TEXT,');
    buffer.writeln('  deprecated_in TEXT,');
    buffer.writeln('  meta TEXT,');
    buffer.writeln('  FOREIGN KEY (event_id) REFERENCES events(id)');
    buffer.writeln(');');
    buffer.writeln();
  }

  void _writeIndexes(StringBuffer buffer) {
    buffer.writeln('-- Create indexes');
    buffer.writeln(
      'CREATE INDEX IF NOT EXISTS idx_events_domain ON events(domain_id);',
    );
    buffer.writeln(
      'CREATE INDEX IF NOT EXISTS idx_parameters_event ON parameters(event_id);',
    );
    buffer.writeln();
  }

  void _writeData(
    StringBuffer buffer,
    List<MapEntry<String, AnalyticsDomain>> domains,
  ) {
    buffer.writeln('-- Insert domain data');
    var domainId = 1;
    final domainIdMap = <String, int>{};

    for (final entry in domains) {
      final domain = entry.value;
      domainIdMap[domain.name] = domainId;
      buffer.writeln(
        'INSERT INTO domains (id, name, event_count, parameter_count) '
        "VALUES ($domainId, '${_escape(domain.name)}', "
        '${domain.eventCount}, ${domain.parameterCount});',
      );
      domainId++;
    }
    buffer.writeln();

    buffer.writeln('-- Insert event data');
    var eventId = 1;

    for (final entry in domains) {
      final domain = entry.value;
      final dId = domainIdMap[domain.name]!;
      final events = _sortedEvents(domain.events);

      for (final event in events) {
        final eventName =
            EventNaming.resolveEventName(domain.name, event, naming);
        final identifier =
            EventNaming.resolveIdentifier(domain.name, event, naming);
        final replacement = event.replacement != null
            ? "'${_escape(event.replacement!)}'"
            : 'NULL';
        final addedIn =
            event.addedIn != null ? "'${_escape(event.addedIn!)}'" : 'NULL';
        final deprecatedIn = event.deprecatedIn != null
            ? "'${_escape(event.deprecatedIn!)}'"
            : 'NULL';
        final customEventName = event.customEventName != null
            ? "'${_escape(event.customEventName!)}'"
            : 'NULL';
        final dualWriteTo = _jsonOrNull(event.dualWriteTo);
        final meta = _jsonOrNull(event.meta);
        final sourcePath = event.sourcePath != null
            ? "'${_escape(event.sourcePath!)}'"
            : 'NULL';
        final lineNumber =
            event.lineNumber != null ? event.lineNumber.toString() : 'NULL';

        buffer.writeln(
          'INSERT INTO events (id, domain_id, name, event_name, identifier, description, deprecated, replacement, added_in, deprecated_in, custom_event_name, dual_write_to, meta, source_path, line_number) '
          "VALUES ($eventId, $dId, '${_escape(event.name)}', "
          "'${_escape(eventName)}', '${_escape(identifier)}', '${_escape(event.description)}', "
          '${event.deprecated ? 1 : 0}, $replacement, $addedIn, '
          '$deprecatedIn, $customEventName, $dualWriteTo, $meta, '
          '$sourcePath, $lineNumber);',
        );

        // Insert parameters
        for (final param in _sortedParameters(event.parameters)) {
          final nullable = param.isNullable ? 1 : 0;
          final desc = param.description != null
              ? "'${_escape(param.description!)}'"
              : 'NULL';
          final allowed = _jsonOrNull(param.allowedValues);
          final regex =
              param.regex != null ? "'${_escape(param.regex!)}'" : 'NULL';
          final minLength =
              param.minLength != null ? param.minLength.toString() : 'NULL';
          final maxLength =
              param.maxLength != null ? param.maxLength.toString() : 'NULL';
          final min = param.min != null ? param.min.toString() : 'NULL';
          final max = param.max != null ? param.max.toString() : 'NULL';
          final operations = _jsonOrNull(param.operations);
          final addedInParam =
              param.addedIn != null ? "'${_escape(param.addedIn!)}'" : 'NULL';
          final deprecatedInParam = param.deprecatedIn != null
              ? "'${_escape(param.deprecatedIn!)}'"
              : 'NULL';
          final metaParam = _jsonOrNull(param.meta);
          final sourceName = param.sourceName != null
              ? "'${_escape(param.sourceName!)}'"
              : 'NULL';
          buffer.writeln(
            'INSERT INTO parameters (event_id, name, source_name, code_name, type, nullable, description, allowed_values, regex, min_length, max_length, min, max, operations, added_in, deprecated_in, meta) '
            "VALUES ($eventId, '${_escape(param.name)}', $sourceName, '${_escape(param.codeName)}', "
            "'${_escape(param.type)}', $nullable, $desc, $allowed, $regex, $minLength, "
            '$maxLength, $min, $max, $operations, $addedInParam, '
            '$deprecatedInParam, $metaParam);',
          );
        }

        eventId++;
      }
    }
    buffer.writeln();
  }

  void _writeViews(StringBuffer buffer) {
    buffer.writeln('-- Create useful views');
    buffer.writeln('CREATE VIEW IF NOT EXISTS events_with_domain AS');
    buffer.writeln('SELECT ');
    buffer.writeln('  e.id,');
    buffer.writeln('  d.name AS domain,');
    buffer.writeln('  e.name AS event,');
    buffer.writeln('  e.event_name,');
    buffer.writeln('  e.identifier,');
    buffer.writeln('  e.description,');
    buffer.writeln('  e.deprecated,');
    buffer.writeln('  e.replacement,');
    buffer.writeln('  e.added_in,');
    buffer.writeln('  e.deprecated_in,');
    buffer.writeln('  e.custom_event_name,');
    buffer.writeln('  e.dual_write_to,');
    buffer.writeln('  e.meta');
    buffer.writeln('FROM events e');
    buffer.writeln('JOIN domains d ON e.domain_id = d.id;');
    buffer.writeln();

    buffer.writeln('CREATE VIEW IF NOT EXISTS parameters_with_event AS');
    buffer.writeln('SELECT');
    buffer.writeln('  p.id,');
    buffer.writeln('  d.name AS domain,');
    buffer.writeln('  e.name AS event,');
    buffer.writeln('  e.event_name,');
    buffer.writeln('  p.name AS parameter,');
    buffer.writeln('  p.source_name,');
    buffer.writeln('  p.code_name,');
    buffer.writeln('  p.type,');
    buffer.writeln('  p.nullable,');
    buffer.writeln('  p.description,');
    buffer.writeln('  p.allowed_values,');
    buffer.writeln('  p.regex,');
    buffer.writeln('  p.min_length,');
    buffer.writeln('  p.max_length,');
    buffer.writeln('  p.min,');
    buffer.writeln('  p.max,');
    buffer.writeln('  p.operations,');
    buffer.writeln('  p.added_in,');
    buffer.writeln('  p.deprecated_in,');
    buffer.writeln('  p.meta');
    buffer.writeln('FROM parameters p');
    buffer.writeln('JOIN events e ON p.event_id = e.id');
    buffer.writeln('JOIN domains d ON e.domain_id = d.id;');
    buffer.writeln();
  }

  /// Escapes SQL values
  String _escape(String value) {
    return value.replaceAll("'", "''");
  }

  List<MapEntry<String, AnalyticsDomain>> _sortedDomains(
    Map<String, AnalyticsDomain> domains,
  ) {
    final entries = domains.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }

  List<AnalyticsEvent> _sortedEvents(List<AnalyticsEvent> events) {
    return events.toList()
      ..sort((a, b) => a.name.toString().compareTo(b.name.toString()));
  }

  List<AnalyticsParameter> _sortedParameters(
    List<AnalyticsParameter> parameters,
  ) {
    return parameters.toList()
      ..sort((a, b) => a.name.toString().compareTo(b.name.toString()));
  }

  String _jsonOrNull(Object? value) {
    if (value == null) return 'NULL';
    if (value is Iterable && value.isEmpty) return 'NULL';
    if (value is Map && value.isEmpty) return 'NULL';

    final encoded = value is Map
        ? jsonEncode(
            Map.fromEntries(
              value.entries.toList()
                ..sort(
                  (a, b) => a.key.toString().compareTo(b.key.toString()),
                ),
            ),
          )
        : jsonEncode(value);

    return "'${_escape(encoded)}'";
  }
}
