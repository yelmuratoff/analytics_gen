import 'dart:io';

import '../../models/analytics_event.dart';
import '../generation_metadata.dart';

/// Generates SQL schema and data inserts for analytics events.
final class SqlGenerator {
  /// Generates SQL file with schema and data
  Future<void> generate(
    Map<String, AnalyticsDomain> domains,
    String outputPath,
  ) async {
    final buffer = StringBuffer();

    final metadata = GenerationMetadata.fromDomains(domains);

    _writeHeader(buffer, metadata);
    _writeSchema(buffer);
    _writeIndexes(buffer);
    _writeData(buffer, domains);
    _writeViews(buffer);

    await File(outputPath).writeAsString(buffer.toString());
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
    buffer.writeln('  description TEXT NOT NULL,');
    buffer.writeln('  deprecated INTEGER NOT NULL DEFAULT 0,');
    buffer.writeln('  replacement TEXT,');
    buffer.writeln('  FOREIGN KEY (domain_id) REFERENCES domains(id),');
    buffer.writeln('  UNIQUE(domain_id, name)');
    buffer.writeln(');');
    buffer.writeln();

    buffer.writeln('-- Create parameters table');
    buffer.writeln('CREATE TABLE IF NOT EXISTS parameters (');
    buffer.writeln('  id INTEGER PRIMARY KEY AUTOINCREMENT,');
    buffer.writeln('  event_id INTEGER NOT NULL,');
    buffer.writeln('  name TEXT NOT NULL,');
    buffer.writeln('  type TEXT NOT NULL,');
    buffer.writeln('  nullable INTEGER NOT NULL,');
    buffer.writeln('  description TEXT,');
    buffer.writeln('  allowed_values TEXT,');
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
    Map<String, AnalyticsDomain> domains,
  ) {
    buffer.writeln('-- Insert domain data');
    var domainId = 1;
    final domainIdMap = <String, int>{};

    for (final domain in domains.values) {
      domainIdMap[domain.name] = domainId;
      buffer.writeln(
        "INSERT INTO domains (id, name, event_count, parameter_count) "
        "VALUES ($domainId, '${_escape(domain.name)}', "
        "${domain.eventCount}, ${domain.parameterCount});",
      );
      domainId++;
    }
    buffer.writeln();

    buffer.writeln('-- Insert event data');
    var eventId = 1;

    for (final domain in domains.values) {
      final dId = domainIdMap[domain.name]!;

      for (final event in domain.events) {
        final eventName =
            event.customEventName ?? '${domain.name}: ${event.name}';
        buffer.writeln(
          "INSERT INTO events (id, domain_id, name, event_name, description, deprecated, replacement) "
          "VALUES ($eventId, $dId, '${_escape(event.name)}', "
          "'${_escape(eventName)}', '${_escape(event.description)}', "
          "${event.deprecated ? 1 : 0}, "
          "${event.replacement != null ? "'${_escape(event.replacement!)}'" : 'NULL'});",
        );

        // Insert parameters
        for (final param in event.parameters) {
          final nullable = param.isNullable ? 1 : 0;
          final desc = param.description != null
              ? "'${_escape(param.description!)}'"
              : 'NULL';
          final allowed =
              (param.allowedValues != null && param.allowedValues!.isNotEmpty)
                  ? "'${_escape(param.allowedValues!.join(', '))}'"
                  : 'NULL';
          buffer.writeln(
            "INSERT INTO parameters (event_id, name, type, nullable, description, allowed_values) "
            "VALUES ($eventId, '${_escape(param.name)}', '${_escape(param.type)}', "
            "$nullable, $desc, $allowed);",
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
    buffer.writeln('  e.description');
    buffer.writeln('FROM events e');
    buffer.writeln('JOIN domains d ON e.domain_id = d.id;');
    buffer.writeln();
  }

  /// Escapes SQL values
  String _escape(String value) {
    return value.replaceAll("'", "''");
  }
}
