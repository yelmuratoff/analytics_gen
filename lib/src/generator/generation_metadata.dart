import 'dart:convert';

import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/serialization.dart';

/// Deterministic metadata used by docs and export generators.
///
/// Captures totals and a fingerprint derived from the canonical ordering of
/// domains, events, and parameters so repeated runs are diff-friendly.
final class GenerationMetadata {
  /// Creates a new generation metadata instance.
  const GenerationMetadata({
    required this.totalDomains,
    required this.totalEvents,
    required this.totalParameters,
    required this.fingerprint,
  });

  /// Creates metadata from analytics domains.
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

  /// The total number of domains.
  final int totalDomains;

  /// The total number of events.
  final int totalEvents;

  /// The total number of parameters.
  final int totalParameters;

  /// A fingerprint representing the current state of domains/events/parameters.
  final String fingerprint;

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
  final sortedDomains = domains.keys.toList()..sort();

  for (final name in sortedDomains) {
    final domain = domains[name]!;
    final map = AnalyticsSerialization.domainToMap(domain);
    final sanitized = _sanitizeForFingerprint(map);
    buffer.writeln(json.encode(sanitized));
  }

  return buffer.toString();
}

/// Recursively sorts keys and removes volatile fields for fingerprinting.
Object? _sanitizeForFingerprint(Object? value) {
  if (value is Map) {
    final sortedKeys = value.keys.map((k) => k.toString()).toList()..sort();
    final result = <String, dynamic>{};
    for (final key in sortedKeys) {
      if (key == 'source_path' || key == 'line_number') continue;
      result[key] = _sanitizeForFingerprint(value[key]);
    }
    return result;
  } else if (value is Iterable) {
    return value.map(_sanitizeForFingerprint).toList();
  }
  return value;
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
