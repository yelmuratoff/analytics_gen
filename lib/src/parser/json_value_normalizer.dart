import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

import '../core/exceptions.dart';

/// Normalizes and validates YAML values into JSON-encodable Dart objects.
///
/// Supported value types:
/// - `null`, `bool`, `num`, `String`
/// - `List` of supported values
/// - `Map<String, ...>` of supported values
///
/// This is used for `meta` fields which are propagated to JSON/SQL exports and
/// embedded into the generated runtime plan.
final class JsonValueNormalizer {
  /// Constructor for JsonValueNormalizer.
  const JsonValueNormalizer();

  /// Normalizes a JSON value.
  Object? normalizeJsonValue(
    Object? value, {
    required String filePath,
    required String context,
    SourceSpan? span,
  }) {
    if (value is YamlScalar) {
      return normalizeJsonValue(
        value.value,
        filePath: filePath,
        context: context,
        span: span ?? value.span,
      );
    }

    if (value == null || value is bool || value is num || value is String) {
      return value;
    }

    if (value is YamlList) {
      return _normalizeJsonList(
        value,
        filePath: filePath,
        context: context,
        span: span ?? value.span,
      );
    }

    if (value is Iterable) {
      return _normalizeJsonList(
        value,
        filePath: filePath,
        context: context,
        span: span,
      );
    }

    if (value is YamlMap) {
      return normalizeJsonMap(
        value,
        filePath: filePath,
        context: context,
        span: span ?? value.span,
      );
    }

    if (value is Map) {
      return normalizeJsonMap(
        value,
        filePath: filePath,
        context: context,
        span: span,
      );
    }

    throw AnalyticsParseException(
      '$context must be JSON-encodable (null, bool, num, String, list, map). '
      'Found unsupported value type: ${value.runtimeType}. '
      'If this came from YAML, quote the value to force a string.',
      filePath: filePath,
      span: span,
    );
  }

  /// Normalizes a JSON map with string keys.
  Map<String, Object?> normalizeJsonMap(
    Map<dynamic, dynamic> map, {
    required String filePath,
    required String context,
    SourceSpan? span,
  }) {
    final normalizedEntries = <MapEntry<String, Object?>>[];

    for (final entry in map.entries) {
      final rawKey = entry.key;
      final key = switch (rawKey) {
        final String s => s,
        final YamlScalar s when s.value is String => s.value as String,
        _ => null,
      };

      if (key == null || key.isEmpty) {
        throw AnalyticsParseException(
          '$context must use non-empty string keys. Found key: '
          '${rawKey.runtimeType} ($rawKey).',
          filePath: filePath,
          span: span,
        );
      }

      normalizedEntries.add(
        MapEntry(
          key,
          normalizeJsonValue(
            entry.value,
            filePath: filePath,
            context: '$context.$key',
            span: span,
          ),
        ),
      );
    }

    // Sort keys for deterministic output.
    normalizedEntries.sort((a, b) => a.key.compareTo(b.key));

    return Map<String, Object?>.unmodifiable(
      {for (final entry in normalizedEntries) entry.key: entry.value},
    );
  }

  List<Object?> _normalizeJsonList(
    Iterable<Object?> values, {
    required String filePath,
    required String context,
    SourceSpan? span,
  }) {
    final out = <Object?>[];
    var index = 0;
    for (final v in values) {
      out.add(
        normalizeJsonValue(
          v,
          filePath: filePath,
          context: '$context[$index]',
          span: span,
        ),
      );
      index++;
    }
    return List<Object?>.unmodifiable(out);
  }
}
