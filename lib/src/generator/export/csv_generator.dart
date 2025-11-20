// dart:io not required directly
import '../../config/naming_strategy.dart';
import '../../models/analytics_event.dart';
import '../../util/event_naming.dart';
import '../../util/file_utils.dart';

/// Generates Excel-compatible CSV export of analytics events.
final class CsvGenerator {
  /// Creates a new CSV generator.
  CsvGenerator({required this.naming});

  /// The naming strategy to use.
  final NamingStrategy naming;

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
  }

  Future<void> _generateEventsCsv(
    Map<String, AnalyticsDomain> domains,
    String outputPath,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln(
      'Domain,Event Name,Description,Deprecated,Replacement,Metadata',
    );

    for (final domain in domains.values) {
      for (final event in domain.events) {
        final eventName =
            EventNaming.resolveEventName(domain.name, event, naming);
        final meta = event.meta.isEmpty
            ? ''
            : event.meta.entries.map((e) => '${e.key}=${e.value}').join('; ');

        buffer.writeln(
          '${_escape(domain.name)},'
          '${_escape(eventName)},'
          '${_escape(event.description)},'
          '${event.deprecated},'
          '${_escape(event.replacement ?? '')},'
          '${_escape(meta)}',
        );
      }
    }
    await writeFileIfContentChanged(outputPath, buffer.toString());
  }

  Future<void> _generateParametersCsv(
    Map<String, AnalyticsDomain> domains,
    String outputPath,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln(
      'Parameter Name,Type,Nullable,Description,Allowed Values,Validation,Metadata',
    );

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

    for (final param in uniqueParams.values) {
      final allowed =
          (param.allowedValues != null && param.allowedValues!.isNotEmpty)
              ? param.allowedValues!.join('|')
              : '';

      final validation = <String>[];
      if (param.regex != null) validation.add('regex:${param.regex}');
      if (param.minLength != null) validation.add('min_len:${param.minLength}');
      if (param.maxLength != null) validation.add('max_len:${param.maxLength}');
      if (param.min != null) validation.add('min:${param.min}');
      if (param.max != null) validation.add('max:${param.max}');

      final meta = param.meta.isNotEmpty
          ? param.meta.entries.map((e) => '${e.key}=${e.value}').join(';')
          : '';

      buffer.writeln(
        '${_escape(param.name)},'
        '${_escape(param.type)},'
        '${param.isNullable},'
        '${_escape(param.description ?? '')},'
        '${_escape(allowed)},'
        '${_escape(validation.join(';'))},'
        '${_escape(meta)}',
      );
    }
    await writeFileIfContentChanged(outputPath, buffer.toString());
  }

  Future<void> _generateMetadataCsv(
    Map<String, AnalyticsDomain> domains,
    String outputPath,
  ) async {
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
    await writeFileIfContentChanged(outputPath, buffer.toString());
  }

  Future<void> _generateEventParametersCsv(
    Map<String, AnalyticsDomain> domains,
    String outputPath,
  ) async {
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
