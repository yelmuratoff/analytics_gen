import 'dart:convert';

import 'package:analytics_gen/src/models/analytics_domain.dart';

import '../../config/naming_strategy.dart';
import '../../util/event_naming.dart';
// dart:io not required directly since file utils handle IO
import '../../util/file_utils.dart';
import '../generation_metadata.dart';

/// Generates JSON export of analytics events (pretty and minified).
final class JsonGenerator {
  /// Creates a new JSON generator.
  JsonGenerator({required this.naming});

  /// The naming strategy to use.
  final NamingStrategy naming;

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
        final domainName = entry.key;
        final domain = entry.value;

        return {
          'name': domainName,
          'event_count': domain.eventCount,
          'parameter_count': domain.parameterCount,
          'events': domain.events.map((event) {
            final eventMap = event.toMap();

            // Add computed fields
            eventMap['event_name'] =
                EventNaming.resolveEventName(domainName, event, naming);
            eventMap['identifier'] =
                EventNaming.resolveIdentifier(domainName, event, naming);

            // Ensure parameters are also maps (handled by event.toMap())
            // We can optionally process parameters here if needed, but toMap should suffice.

            // Remove fields that might be redundant or internal if necessary,
            // but for "export" usually more data is better.
            // The previous implementation conditionally added some fields (e.g. replacement).
            // toMap includes them with null values if they are null.
            // We might want to filter out nulls to keep JSON clean?
            // The previous implementation used `if (event.replacement != null) ...`
            // Let's filter nulls from the map to match that behavior and keep it clean.
            eventMap.removeWhere((key, value) =>
                value == null ||
                (value is Iterable && value.isEmpty) ||
                (value is Map && value.isEmpty));

            // Remove internal fields that shouldn't be exported
            eventMap.remove('source_path');

            // Also filter nulls from parameters
            if (eventMap['parameters'] is List) {
              eventMap['parameters'] =
                  (eventMap['parameters'] as List).map((p) {
                if (p is Map) {
                  final pMap = Map<String, dynamic>.from(p);
                  pMap.removeWhere((key, value) =>
                      value == null ||
                      (value is Iterable && value.isEmpty) ||
                      (value is Map && value.isEmpty));
                  pMap.remove('source_path');
                  return pMap;
                }
                return p;
              }).toList();
            }

            return eventMap;
          }).toList(),
        };
      }).toList(),
    };
  }
}
