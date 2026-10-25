import 'package:analytics_gen/src/core/exceptions.dart';
import 'package:source_span/source_span.dart';
import 'package:test/test.dart';

void main() {
  group('AnalyticsException', () {
    test('is base class for all analytics exceptions', () {
      final parseException = AnalyticsParseException('test');
      final aggregateException = AnalyticsAggregateException([parseException]);
      final generationException = AnalyticsGenerationException('test');

      expect(parseException, isA<AnalyticsException>());
      expect(aggregateException, isA<AnalyticsException>());
      expect(generationException, isA<AnalyticsException>());
    });
  });

  group('AnalyticsParseException', () {
    test('toString omits file info when none provided', () {
      final exception = AnalyticsParseException('bad format');

      expect(exception.toString(), 'FormatException: bad format');
    });

    test('toString includes file path when provided', () {
      final exception = AnalyticsParseException(
        'bad format',
        filePath: 'events/example.yaml',
      );

      expect(
        exception.toString(),
        'FormatException: bad format (file: events/example.yaml)',
      );
    });

    test('toString includes file path and line number when provided', () {
      final exception = AnalyticsParseException(
        'bad format',
        filePath: 'events/example.yaml',
        lineNumber: 42,
      );

      expect(
        exception.toString(),
        'FormatException: bad format (file: events/example.yaml:42)',
      );
    });

    test('toString includes inner error when provided', () {
      final innerError = Exception('original error');
      final exception = AnalyticsParseException(
        'bad format',
        innerError: innerError,
      );

      expect(
        exception.toString(),
        'FormatException: bad format\n  Caused by: Exception: original error',
      );
    });

    test('toString uses span when provided', () {
      final span = SourceSpan(
        SourceLocation(0, sourceUrl: 'test.yaml'),
        SourceLocation(11, sourceUrl: 'test.yaml'),
        'bad content',
      );
      final exception = AnalyticsParseException(
        'bad format',
        span: span,
      );

      expect(
        exception.toString(),
        contains('AnalyticsParseException: bad format'),
      );
      expect(
        exception.toString(),
        contains('bad content'),
      );
    });

    test('fields are properly assigned', () {
      final innerError = Exception('test');
      final span = SourceSpan(
        SourceLocation(0),
        SourceLocation(4),
        'test',
      );

      final exception = AnalyticsParseException(
        'message',
        filePath: 'path.yaml',
        innerError: innerError,
        span: span,
        lineNumber: 10,
      );

      expect(exception.filePath, 'path.yaml');
      expect(exception.innerError, innerError);
      expect(exception.span, span);
      expect(exception.lineNumber, 10);
    });
  });

  group('AnalyticsAggregateException', () {
    test('toString formats multiple errors', () {
      final error1 = AnalyticsParseException('error 1');
      final error2 = AnalyticsParseException('error 2');

      final exception = AnalyticsAggregateException([error1, error2]);

      expect(
        exception.toString(),
        'Found 2 errors during parsing:\n'
        '- FormatException: error 1\n'
        '- FormatException: error 2\n',
      );
    });

    test('errors field is properly assigned', () {
      final errors = [AnalyticsParseException('test')];
      final exception = AnalyticsAggregateException(errors);

      expect(exception.errors, errors);
    });
  });

  group('AnalyticsGenerationException', () {
    test('toString includes message only when no source info', () {
      final exception = AnalyticsGenerationException('generation failed');

      expect(
        exception.toString(),
        'AnalyticsGenerationException: generation failed',
      );
    });

    test('toString includes source path when provided', () {
      final exception = AnalyticsGenerationException(
        'generation failed',
        sourcePath: 'lib/generated.dart',
      );

      expect(
        exception.toString(),
        'AnalyticsGenerationException: generation failed\n'
        'Source: lib/generated.dart',
      );
    });

    test('toString includes source path and line number when provided', () {
      final exception = AnalyticsGenerationException(
        'generation failed',
        sourcePath: 'lib/generated.dart',
        lineNumber: 25,
      );

      expect(
        exception.toString(),
        'AnalyticsGenerationException: generation failed\n'
        'Source: lib/generated.dart:25',
      );
    });

    test('fields are properly assigned', () {
      final exception = AnalyticsGenerationException(
        'test message',
        sourcePath: 'test.dart',
        lineNumber: 5,
      );

      expect(exception.message, 'test message');
      expect(exception.sourcePath, 'test.dart');
      expect(exception.lineNumber, 5);
    });
  });
}
