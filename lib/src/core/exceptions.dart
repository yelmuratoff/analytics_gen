import 'package:source_span/source_span.dart';

/// Base exception for all analytics_gen errors.
///
/// This is a sealed hierarchy, allowing consumers to exhaustively match
/// on specific error types.
sealed class AnalyticsException implements Exception {
  const AnalyticsException();
}

/// Analytics-specific exceptions used by parsers and generation tools.
///
/// These extend the platform's [FormatException] so existing callers
/// that match `FormatException` will continue to work while allowing
/// callers to match analytics-specific errors explicitly.
final class AnalyticsParseException extends FormatException
    implements AnalyticsException {
  /// Creates a new parse exception.
  const AnalyticsParseException(
    super.message, {
    this.filePath,
    this.innerError,
    this.span,
    this.lineNumber,
  });

  /// Optional file path where the error occurred.
  final String? filePath;

  /// Optional underlying error that caused this exception.
  final Object? innerError;

  /// Optional source span indicating the location of the error.
  final SourceSpan? span;

  /// Optional line number (1-based) if span is not available.
  final int? lineNumber;

  @override
  String toString() {
    if (span != null) {
      return 'AnalyticsParseException: $message\n${span!.message(message)}';
    }
    final sb = StringBuffer(super.toString());
    if (filePath != null) {
      sb.write(' (file: $filePath');
      if (lineNumber != null) {
        sb.write(':$lineNumber');
      }
      sb.write(')');
    }
    if (innerError != null) {
      sb.write('\n  Caused by: $innerError');
    }
    return sb.toString();
  }
}

/// Exception thrown when there are multiple parsing errors.
final class AnalyticsAggregateException implements AnalyticsException {
  /// Creates a new aggregate exception.
  const AnalyticsAggregateException(this.errors);

  /// The list of errors that occurred.
  final List<AnalyticsParseException> errors;

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

/// Exception thrown during code generation.
final class AnalyticsGenerationException implements AnalyticsException {
  /// Creates a new generation exception.
  const AnalyticsGenerationException(
    this.message, {
    this.sourcePath,
    this.lineNumber,
  });

  /// The error message.
  final String message;

  /// The source file path where the error occurred.
  final String? sourcePath;

  /// The line number where the error occurred.
  final int? lineNumber;

  @override
  String toString() {
    final sb = StringBuffer('AnalyticsGenerationException: $message');
    if (sourcePath != null) {
      sb.write('\nSource: $sourcePath');
      if (lineNumber != null) {
        sb.write(':$lineNumber');
      }
    }
    return sb.toString();
  }
}
