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

/// Exception thrown when there are multiple parsing errors.
class AnalyticsAggregateException implements Exception {
  final List<AnalyticsParseException> errors;

  AnalyticsAggregateException(this.errors);

  @override
  String toString() {
    final buffer =
        StringBuffer('Found ${errors.length} errors during parsing:\n');
    for (final error in errors) {
      buffer.writeln('- ${error.toString()}');
    }
    return buffer.toString();
  }
}

class AnalyticsGenerationException implements Exception {
  final String message;
  AnalyticsGenerationException(this.message);
  @override
  String toString() => 'AnalyticsGenerationException: $message';
}
