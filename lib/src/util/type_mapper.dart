/// Maps YAML type names to Dart type names for code generation.
///
/// Not exported from the public API.
final class DartTypeMapper {
  const DartTypeMapper._();

  /// Converts a YAML type to its corresponding Dart type.
  ///
  /// Supports common analytics parameter types and custom types.
  ///
  /// Examples:
  /// - `int` → `int`
  /// - `string` → `String`
  /// - `float` → `double`
  /// - `map` → `Map<String, dynamic>`
  /// - `CustomType` → `CustomType` (passthrough)
  static String toDartType(String yamlType) {
    final trimmed = yamlType.trim();
    return switch (trimmed.toLowerCase()) {
      'int' => 'int',
      'bool' => 'bool',
      'float' || 'double' => 'double',
      'string' => 'String',
      'map' => 'Map<String, dynamic>',
      'list' => 'List<dynamic>',
      'datetime' || 'date' => 'DateTime',
      'uri' => 'Uri',
      _ => trimmed, // Pass through custom types unchanged
    };
  }
}
