import 'package:yaml/yaml.dart';

import '../core/exceptions.dart';
import '../util/logger.dart';

/// Typed access to the fields of a tracking plan YAML map.
extension YamlFields on YamlMap {
  /// Returns the value of [key], or null when the key is absent or empty.
  ///
  /// Throws [AnalyticsParseException] pointing at the value when it is not a
  /// [T].
  T? optionalField<T extends Object>(String key, {required String filePath}) {
    final node = nodes[key];
    if (node == null) return null;
    return switch (node.value) {
      null => null,
      final T value => value,
      _ => throw AnalyticsParseException(
          'Field "$key" must be ${_describe(T)}.',
          filePath: filePath,
          span: node.span,
        ),
    };
  }

  /// Logs a warning through [log] for each key that is not in [knownFields].
  ///
  /// The warning names the key, the [owner] it belongs to, and its location
  /// in [filePath].
  void warnUnknownFields(
    Set<String> knownFields, {
    required String owner,
    required String filePath,
    required Logger log,
  }) {
    for (final key in nodes.keys.cast<YamlNode>()) {
      if (knownFields.contains(key.value)) continue;
      final start = key.span.start;
      log.warning(
        '$filePath:${start.line + 1}:${start.column + 1}: '
        'Unknown field "${key.value}" in $owner is ignored.',
      );
    }
  }

  static String _describe(Type type) => switch (type) {
        const (String) => 'a string',
        const (int) => 'an integer',
        const (num) => 'a number',
        const (bool) => 'true or false',
        _ => 'a $type',
      };
}
