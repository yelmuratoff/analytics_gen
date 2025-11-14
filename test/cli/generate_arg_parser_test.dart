import 'package:args/args.dart';
import 'package:test/test.dart';
import '../../bin/generate.dart' as cli;

void main() {
  group('generate.dart ArgParser', () {
    late ArgParser parser;

    setUp(() {
      parser = cli.createArgParser();
    });

    test('defaults to code only with verbose', () {
      final results = parser.parse(const <String>[]);

      expect(results['code'], isTrue);
      expect(results['docs'], isFalse);
      expect(results['exports'], isFalse);
      expect(results['verbose'], isTrue);
    });

    test('supports docs-only generation via --docs --no-code', () {
      final results = parser.parse(const <String>['--docs', '--no-code']);

      expect(results['code'], isFalse);
      expect(results['docs'], isTrue);
      expect(results['exports'], isFalse);
    });

    test('supports exports-only generation via --exports --no-code', () {
      final results = parser.parse(const <String>['--exports', '--no-code']);

      expect(results['code'], isFalse);
      expect(results['docs'], isFalse);
      expect(results['exports'], isTrue);
    });

    test('allows disabling verbose output with --no-verbose', () {
      final results = parser.parse(const <String>['--no-verbose']);

      expect(results['verbose'], isFalse);
    });

    test('supports validate-only flag', () {
      final results = parser.parse(const <String>['--validate-only']);

      expect(results['validate-only'], isTrue);
    });
  });
}
