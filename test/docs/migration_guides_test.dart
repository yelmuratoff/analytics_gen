import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('Migration guides documentation', () {
    test('README links to docs/MIGRATION_GUIDES.md', () {
      final readme = File('README.md').readAsStringSync();
      expect(
        readme,
        contains('docs/MIGRATION_GUIDES.md'),
        reason: 'README should point to the migration guide hub.',
      );
    });

    test('migration guide covers Firebase, Amplitude, Mixpanel', () {
      final guide = File('docs/MIGRATION_GUIDES.md').readAsStringSync();
      expect(guide, contains('Firebase Analytics'));
      expect(guide, contains('Amplitude'));
      expect(guide, contains('Mixpanel'));
    });
  });
}
