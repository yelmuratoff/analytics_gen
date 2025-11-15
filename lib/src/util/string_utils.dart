/// Internal string helpers used by generators.
///
/// Not exported from the public API.
final class StringUtils {
  const StringUtils._();

  /// Capitalizes the first letter and converts snake_case to PascalCase.
  static String capitalizePascal(String text) {
    if (text.isEmpty) return text;

    if (text.contains('_')) {
      return text.split('_').map((part) {
        if (part.isEmpty) return '';
        return part[0].toUpperCase() + part.substring(1);
      }).join('');
    }

    return text[0].toUpperCase() + text.substring(1);
  }

  /// Converts snake_case or kebab-case to lowerCamelCase.
  static String toCamelCase(String text) {
    if (text.isEmpty) return text;
    final parts = text.split(RegExp(r'[_-]')).where((part) => part.isNotEmpty);
    if (parts.isEmpty) return text;
    final sanitized = parts.toList();
    return sanitized.first +
        sanitized
            .skip(1)
            .map((w) => w[0].toUpperCase() + w.substring(1))
            .join();
  }
}
