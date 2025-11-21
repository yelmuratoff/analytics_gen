/// Internal string helpers used by generators.
///
/// Not exported from the public API.
final class StringUtils {
  /// Capitalizes the first letter and converts snake_case to PascalCase.
  ///
  /// Handles edge cases like leading/trailing underscores and multiple consecutive underscores.
  ///
  /// Examples:
  /// - `user_id` → `UserId`
  /// - `_user_id` → `UserId`
  /// - `user__id` → `UserId`
  /// - `user_id_` → `UserId`
  static String capitalizePascal(String text) {
    if (text.isEmpty) return text;

    if (text.contains('_')) {
      return text
          .split('_')
          .where((part) => part.isNotEmpty)
          .map((part) => part[0].toUpperCase() + part.substring(1))
          .join('');
    }

    return text[0].toUpperCase() + text.substring(1);
  }

  /// Converts snake_case or kebab-case to lowerCamelCase.
  ///
  /// Handles edge cases like leading/trailing separators and multiple consecutive separators.
  ///
  /// Examples:
  /// - `user_id` → `userId`
  /// - `_user_id` → `userId`
  /// - `user__id` → `userId`
  /// - `user_id_` → `userId`
  /// - `user-id` → `userId`
  static String toCamelCase(String text) {
    if (text.isEmpty) return text;

    final parts =
        text.split(RegExp(r'[_-]')).where((part) => part.isNotEmpty).toList();

    if (parts.isEmpty) return text;

    return parts.first.toLowerCase() +
        parts
            .skip(1)
            .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
            .join();
  }

  /// Escapes single quotes, backslashes, and dollar signs for use in Dart string literals.
  static String escapeSingleQuoted(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll(r'$', r'\$');
  }
}
