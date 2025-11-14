import 'package:analytics_gen/src/util/string_utils.dart';
import 'package:test/test.dart';

void main() {
  group('StringUtils', () {
    test('capitalizePascal handles simple and snake_case', () {
      expect(StringUtils.capitalizePascal('auth'), equals('Auth'));
      expect(StringUtils.capitalizePascal('screen_view'), equals('ScreenView'));
      expect(StringUtils.capitalizePascal(''), equals(''));
    });

    test('toCamelCase handles snake_case and kebab-case', () {
      expect(StringUtils.toCamelCase('method'), equals('method'));
      expect(StringUtils.toCamelCase('screen_view'), equals('screenView'));
      expect(StringUtils.toCamelCase('screen-view'), equals('screenView'));
      expect(StringUtils.toCamelCase(''), equals(''));
    });
  });
}

