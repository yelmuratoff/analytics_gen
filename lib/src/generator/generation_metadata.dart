import 'dart:convert';

import '../models/analytics_event.dart';

/// Deterministic metadata used by docs and export generators.
///
/// Captures totals and a fingerprint derived from the canonical ordering of
/// domains, events, and parameters so repeated runs are diff-friendly.
final class GenerationMetadata {
  final int totalDomains;
  final int totalEvents;
  final int totalParameters;
  final String fingerprint;

  const GenerationMetadata({
    required this.totalDomains,
    required this.totalEvents,
    required this.totalParameters,
    required this.fingerprint,
  });

  factory GenerationMetadata.fromDomains(
    Map<String, AnalyticsDomain> domains,
  ) {
    final totalEvents =
        domains.values.fold(0, (sum, domain) => sum + domain.eventCount);
    final totalParameters =
        domains.values.fold(0, (sum, domain) => sum + domain.parameterCount);

    final canonical = _buildCanonicalSignature(domains);
    final fingerprint = _fingerprintFor(canonical);

    return GenerationMetadata(
      totalDomains: domains.length,
      totalEvents: totalEvents,
      totalParameters: totalParameters,
      fingerprint: fingerprint,
    );
  }

  /// Serializes metadata for JSON exports.
  Map<String, dynamic> toJson() => {
        'fingerprint': fingerprint,
        'total_domains': totalDomains,
        'total_events': totalEvents,
        'total_parameters': totalParameters,
      };
}

String _buildCanonicalSignature(Map<String, AnalyticsDomain> domains) {
  final buffer = StringBuffer();
  final sortedDomains = domains.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  for (final entry in sortedDomains) {
    final domain = entry.value;
    buffer.writeln(domain.name);

    final sortedEvents = domain.events.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    for (final event in sortedEvents) {
      buffer
        ..writeln(event.name)
        ..writeln(event.description)
        ..writeln(event.customEventName ?? '')
        ..writeln(event.deprecated ? '1' : '0')
        ..writeln(event.replacement ?? '');

      final sortedParams = event.parameters.toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      for (final param in sortedParams) {
        buffer
          ..writeln(param.name)
          ..writeln(param.type)
          ..writeln(param.isNullable ? '1' : '0')
          ..writeln(param.description ?? '')
          ..writeln(param.allowedValues?.join('|') ?? '');
      }

      buffer.writeln('--event--');
    }

    buffer.writeln('--domain--');
  }

  return buffer.toString();
}

String _fingerprintFor(String canonical) {
  const int fnvPrime = 0x100000001b3;
  const int fnvOffset = 0xcbf29ce484222325;
  const int mask64 = 0xffffffffffffffff;

  var hash = fnvOffset;
  final bytes = utf8.encode(canonical);

  for (final byte in bytes) {
    hash ^= byte;
    hash = (hash * fnvPrime) & mask64;
  }

  return hash.toRadixString(16).padLeft(16, '0');
}
