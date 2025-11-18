// dart:io not required directly
import '../../util/file_utils.dart';

import '../../util/event_naming.dart';
import '../../config/naming_strategy.dart';
import '../../models/analytics_event.dart';

/// Generates Excel-compatible CSV export of analytics events.
final class CsvGenerator {
  final NamingStrategy naming;

  CsvGenerator({required this.naming});

  /// Generates CSV file from analytics domains
  Future<void> generate(
    Map<String, AnalyticsDomain> domains,
    String outputPath,
  ) async {
    final buffer = StringBuffer();

    // CSV Header
    buffer.writeln(
      'Domain,Action,Event Name,Description,Parameters,Deprecated,Replacement',
    );

    // Data rows
    for (final domain in domains.values) {
      for (final event in domain.events) {
        final eventName =
            EventNaming.resolveEventName(domain.name, event, naming);
        final parameters = event.parameters.map((p) {
          final typeStr = '${p.name} (${p.type}${p.isNullable ? '?' : ''})';
          final desc = p.description != null ? ': ${p.description}' : '';
          final allowed =
              (p.allowedValues != null && p.allowedValues!.isNotEmpty)
                  ? ' {allowed: ${p.allowedValues!.join('|')}}'
                  : '';
          return '$typeStr$desc$allowed';
        }).join('; ');

        buffer.writeln(
          '${_escape(domain.name)},'
          '${_escape(event.name)},'
          '${_escape(eventName)},'
          '${_escape(event.description)},'
          '${_escape(parameters)},'
          '${event.deprecated},'
          '${_escape(event.replacement ?? '')}',
        );
      }
    }

    await writeFileIfContentChanged(outputPath, buffer.toString());
  }

  /// Escapes CSV values
  String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
