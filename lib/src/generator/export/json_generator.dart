import 'dart:convert';

import '../../config/naming_strategy.dart';
import '../../models/analytics_event.dart';
import '../../util/event_naming.dart';
// dart:io not required directly since file utils handle IO
import '../../util/file_utils.dart';
import '../generation_metadata.dart';

/// Generates JSON export of analytics events (pretty and minified).
final class JsonGenerator {
  final NamingStrategy naming;

  JsonGenerator({required this.naming});

  /// Generates both pretty and minified JSON files
  Future<void> generate(
    Map<String, AnalyticsDomain> domains,
    String outputDir,
  ) async {
    final metadata = GenerationMetadata.fromDomains(domains);
    final data = _buildJsonStructure(domains, metadata);

    // Pretty JSON
    final prettyJson = const JsonEncoder.withIndent('  ').convert(data);
    await writeFileIfContentChanged(
        '$outputDir/analytics_events.json', prettyJson);

    // Minified JSON
    final minifiedJson = jsonEncode(data);
    await writeFileIfContentChanged(
        '$outputDir/analytics_events.min.json', minifiedJson);
  }

  /// Builds the JSON data structure
  Map<String, dynamic> _buildJsonStructure(
    Map<String, AnalyticsDomain> domains,
    GenerationMetadata metadata,
  ) {
    return {
      'metadata': metadata.toJson(),
      'domains': domains.entries.map((entry) {
        return {
          'name': entry.key,
          'event_count': entry.value.eventCount,
          'parameter_count': entry.value.parameterCount,
          'events': entry.value.events.map((event) {
            return {
              'name': event.name,
              'event_name':
                  EventNaming.resolveEventName(entry.key, event, naming),
              'identifier':
                  EventNaming.resolveIdentifier(entry.key, event, naming),
              'description': event.description,
              'deprecated': event.deprecated,
              if (event.replacement != null) 'replacement': event.replacement,
              if (event.meta.isNotEmpty) 'meta': event.meta,
              'parameters': event.parameters.map((p) {
                return {
                  'name': p.name,
                  if (p.codeName != p.name) 'code_name': p.codeName,
                  'type': p.type,
                  'nullable': p.isNullable,
                  if (p.description != null) 'description': p.description,
                  if (p.allowedValues != null && p.allowedValues!.isNotEmpty)
                    'allowed_values': p.allowedValues,
                  if (p.meta.isNotEmpty) 'meta': p.meta,
                };
              }).toList(),
            };
          }).toList(),
        };
      }).toList(),
    };
  }
}
