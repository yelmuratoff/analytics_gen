import 'package:analytics_gen/src/util/project_revision.dart';
import 'package:test/test.dart';

void main() {
  group('computeRevision', () {
    // Reference values produced by the Studio TypeScript implementation
    // (project-meta.ts). They lock cross-language hash parity: a studio-saved
    // file and a CI-generated file get the same revision for the same content.
    test('matches the Studio reference hash for empty content', () {
      final content = {
        'config': <String, dynamic>{},
        'eventFiles': <dynamic>[],
        'sharedParamFiles': <dynamic>[],
        'contextFiles': <dynamic>[],
      };
      expect(computeRevision(content), '07f86068ecf134');
    });

    test('matches the Studio reference hash for sample content', () {
      final content = {
        'config': {'a': 1, 'b': 2},
        'eventFiles': [
          {'fileName': 'x.yaml', 'domains': <String, dynamic>{}},
        ],
        'sharedParamFiles': <dynamic>[],
        'contextFiles': <dynamic>[],
      };
      expect(computeRevision(content), '17479df14a1c68');
    });

    test('is independent of object key ordering', () {
      final a = {
        'config': {'a': 1, 'b': 2},
        'eventFiles': <dynamic>[],
      };
      final b = {
        'eventFiles': <dynamic>[],
        'config': {'b': 2, 'a': 1},
      };
      expect(computeRevision(a), computeRevision(b));
    });

    test('changes when content changes', () {
      final before = computeRevision({'config': <String, dynamic>{}});
      final after = computeRevision({
        'config': {
          'inputs': {'events': 'events'}
        },
      });
      expect(after, isNot(before));
    });
  });
}
