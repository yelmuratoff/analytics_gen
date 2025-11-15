import 'package:analytics_gen/src/core/exceptions.dart';
import 'package:test/test.dart';

void main() {
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
  });
}
