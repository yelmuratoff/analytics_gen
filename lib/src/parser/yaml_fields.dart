import 'package:yaml/yaml.dart';

import '../core/exceptions.dart';

/// Typed access to scalar fields of a tracking plan YAML map.
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

  static String _describe(Type type) => switch (type) {
        const (String) => 'a string',
        const (int) => 'an integer',
        const (num) => 'a number',
        const (bool) => 'true or false',
        _ => 'a $type',
      };
}
