/// Analytics-specific exceptions used by parsers and generation tools.
///
/// These extend the platform's [FormatException] so existing callers
/// that match `FormatException` will continue to work while allowing
/// callers to match analytics-specific errors explicitly.
class AnalyticsParseException extends FormatException {
  /// Optional file path where the error occurred.
  final String? filePath;

  AnalyticsParseException(super.message, {this.filePath});

  @override
  String toString() =>
      '${super.toString()}${filePath != null ? ' (file: $filePath)' : ''}';
}
