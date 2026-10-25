import 'dart:io';

import 'package:analytics_gen/src/core/exceptions.dart';
import 'package:analytics_gen/src/pipeline/failure_report.dart';
import 'package:test/test.dart';

void main() {
  group('isInvalidInputError', () {
    test('is true for analytics, format and file system errors', () {
      expect(
        isInvalidInputError(const AnalyticsGenerationException('x')),
        isTrue,
      );
      expect(isInvalidInputError(const FormatException('bad flag')), isTrue);
      expect(
        isInvalidInputError(const FileSystemException('missing', '/lib')),
        isTrue,
      );
    });

    test('is false for other failures', () {
      expect(isInvalidInputError(StateError('bug')), isFalse);
      expect(isInvalidInputError(Exception('io')), isFalse);
    });
  });
}
