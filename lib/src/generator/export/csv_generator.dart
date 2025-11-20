// dart:io not required directly
import '../../config/naming_strategy.dart';
import '../../models/analytics_event.dart';
import '../../util/event_naming.dart';
import '../../util/file_utils.dart';

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
      'Domain,Action,Event Name,Description,Parameters,Deprecated,Replacement,Metadata',
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
          final meta = p.meta.isNotEmpty
              ? ' [${p.meta.entries.map((e) => '${e.key}=${e.value}').join(';')}]'
              : '';
          return '$typeStr$desc$allowed$meta';
        }).join('; ');

        final meta = event.meta.isEmpty
            ? ''
            : event.meta.entries.map((e) => '${e.key}=${e.value}').join('; ');

        buffer.writeln(
          '${_escape(domain.name)},'
          '${_escape(event.name)},'
          '${_escape(eventName)},'
          '${_escape(event.description)},'
          '${_escape(parameters)},'
          '${event.deprecated},'
          '${_escape(event.replacement ?? '')},'
          '${_escape(meta)}',
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
