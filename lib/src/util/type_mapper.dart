/// Maps YAML type names to Dart type names for code generation.
///
/// Not exported from the public API.
final class DartTypeMapper {
  const DartTypeMapper._();

  static const Map<String, String> _kTypeMap = {
    'int': 'int',
    'bool': 'bool',
    'float': 'double',
    'double': 'double',
    'string': 'String',
    'map': 'Map<String, dynamic>',
    'list': 'List<dynamic>',
    'datetime': 'DateTime',
    'date': 'DateTime',
    'uri': 'Uri',
    'number': 'num',
  };

  /// Converts a YAML type to its corresponding Dart type.
  ///
  /// Uses a small lookup table and falls back to returning the original
  /// string for custom types (preserves casing in that case).
  static String toDartType(String yamlType) {
    final key = yamlType.trim().toLowerCase();
    return _kTypeMap[key] ?? yamlType.trim();
  }
}
