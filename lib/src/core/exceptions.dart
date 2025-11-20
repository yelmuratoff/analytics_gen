/// Analytics-specific exceptions used by parsers and generation tools.
///
/// These extend the platform's [FormatException] so existing callers
/// that match `FormatException` will continue to work while allowing
/// callers to match analytics-specific errors explicitly.
class AnalyticsParseException extends FormatException {
  /// Optional file path where the error occurred.
  final String? filePath;

  /// Optional underlying error that caused this exception.
  final Object? innerError;

  AnalyticsParseException(super.message, {this.filePath, this.innerError});

  @override
  String toString() {
    final sb = StringBuffer(super.toString());
    if (filePath != null) {
      sb.write(' (file: $filePath)');
    }
    if (innerError != null) {
      sb.write('\n  Caused by: $innerError');
    }
    return sb.toString();
  }
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
