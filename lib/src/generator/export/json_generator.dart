import 'dart:convert';

import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/serialization.dart';

import '../../config/naming_strategy.dart';
import '../../util/event_naming.dart';
// dart:io not required directly since file utils handle IO
import '../generation_metadata.dart';
import '../output_manager.dart';

/// Generates JSON export of analytics events (pretty and minified).
final class JsonGenerator {
  /// Creates a new JSON generator.
  JsonGenerator({
    required this.naming,
    this.outputManager = const OutputManager(),
  });

  /// The naming strategy to use.
  final NamingStrategy naming;

  /// The output manager to use.
  final OutputManager outputManager;

  /// Generates both pretty and minified JSON files
  Future<void> generate(
    Map<String, AnalyticsDomain> domains,
    String outputDir,
  ) async {
    final metadata = GenerationMetadata.fromDomains(domains);
    final data = _buildJsonStructure(domains, metadata);

    // Pretty JSON
    final prettyJson = const JsonEncoder.withIndent('  ').convert(data);
    await outputManager.writeFileIfContentChanged(
        '$outputDir/analytics_events.json', prettyJson);

    // Minified JSON
    final minifiedJson = jsonEncode(data);
    await outputManager.writeFileIfContentChanged(
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
            final eventMap = AnalyticsSerialization.eventToMap(event);

            // Add computed fields
            eventMap['event_name'] =
                EventNaming.resolveEventName(domainName, event, naming);
            eventMap['identifier'] =
                EventNaming.resolveIdentifier(domainName, event, naming);

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
