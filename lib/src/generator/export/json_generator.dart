import 'dart:convert';
import 'dart:io';

import '../../models/analytics_event.dart';

/// Generates JSON export of analytics events (pretty and minified).
final class JsonGenerator {
  /// Generates both pretty and minified JSON files
  Future<void> generate(
    Map<String, AnalyticsDomain> domains,
    String outputDir,
  ) async {
    final data = _buildJsonStructure(domains);

    // Pretty JSON
    final prettyJson = const JsonEncoder.withIndent('  ').convert(data);
    await File('$outputDir/analytics_events.json').writeAsString(prettyJson);

    // Minified JSON
    final minifiedJson = jsonEncode(data);
    await File('$outputDir/analytics_events.min.json')
        .writeAsString(minifiedJson);
  }

  /// Builds the JSON data structure
  Map<String, dynamic> _buildJsonStructure(
    Map<String, AnalyticsDomain> domains,
  ) {
    return {
      'metadata': {
        'generated_at': DateTime.now().toIso8601String(),
        'total_domains': domains.length,
        'total_events': domains.values.fold(0, (sum, d) => sum + d.eventCount),
        'total_parameters':
            domains.values.fold(0, (sum, d) => sum + d.parameterCount),
      },
      'domains': domains.entries.map((entry) {
        return {
          'name': entry.key,
          'event_count': entry.value.eventCount,
          'parameter_count': entry.value.parameterCount,
          'events': entry.value.events.map((event) {
            return {
              'name': event.name,
              'event_name':
                  event.customEventName ?? '${entry.key}: ${event.name}',
              'description': event.description,
              'deprecated': event.deprecated,
              if (event.replacement != null)
                'replacement': event.replacement,
              'parameters': event.parameters.map((p) {
                return {
                  'name': p.name,
                  'type': p.type,
                  'nullable': p.isNullable,
                  if (p.description != null) 'description': p.description,
                  if (p.allowedValues != null && p.allowedValues!.isNotEmpty)
                    'allowed_values': p.allowedValues,
                };
              }).toList(),
            };
          }).toList(),
        };
      }).toList(),
    };
  }
}
