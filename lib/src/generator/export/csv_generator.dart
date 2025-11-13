import 'dart:io';

import '../../models/analytics_event.dart';

/// Generates Excel-compatible CSV export of analytics events.
final class CsvGenerator {
  /// Generates CSV file from analytics domains
  Future<void> generate(
    Map<String, AnalyticsDomain> domains,
    String outputPath,
  ) async {
    final buffer = StringBuffer();

    // CSV Header
    buffer.writeln('Domain,Action,Event Name,Description,Parameters');

    // Data rows
    for (final domain in domains.values) {
      for (final event in domain.events) {
        final eventName =
            event.customEventName ?? '${domain.name}: ${event.name}';
        final parameters = event.parameters.map((p) {
          final typeStr = '${p.name} (${p.type}${p.isNullable ? '?' : ''})';
          return p.description != null ? '$typeStr: ${p.description}' : typeStr;
        }).join('; ');

        buffer.writeln(
          '${_escape(domain.name)},${_escape(event.name)},${_escape(eventName)},${_escape(event.description)},${_escape(parameters)}',
        );
      }
    }

    await File(outputPath).writeAsString(buffer.toString());
  }

  /// Escapes CSV values
  String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
