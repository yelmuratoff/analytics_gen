import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('pull_request_template', () {
    test('exists and links to the code review checklist', () {
      final file = File('.github/pull_request_template.md');

      expect(file.existsSync(), isTrue,
          reason: 'PR template must exist to enforce review guardrails.');

      final content = file.readAsStringSync();

      expect(
        content,
        contains('docs/CODE_REVIEW.md'),
        reason: 'Template should link to the docs/CODE_REVIEW.md checklist.',
      );
      expect(
        content,
        contains('I walked through'),
        reason: 'Template should require authors acknowledge the checklist.',
      );
    });
  });
}
