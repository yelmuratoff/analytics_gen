import 'package:analytics_gen/src/cli/arguments.dart' as cli;
import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:args/args.dart';
import 'package:test/test.dart';

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

    test('plan flag defaults to false', () {
      final results = parser.parse(const <String>[]);
      expect(results['plan'], isFalse);
    });

    test('plan flag enables --plan', () {
      final results = parser.parse(const <String>['--plan']);
      expect(results['plan'], isTrue);
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

    test('help flag is available', () {
      final results = parser.parse(const <String>['--help']);

      expect(results['help'], isTrue);
    });

    test('resolveDocsFlag falls back to config when flag omitted', () {
      final results = parser.parse(const <String>[]);
      const config =
          AnalyticsConfig(targets: AnalyticsTargets(generateDocs: true));

      expect(cli.resolveDocsFlag(results, config), isTrue);
    });

    test('resolveDocsFlag respects CLI override', () {
      final results = parser.parse(const <String>['--no-docs']);
      const config =
          AnalyticsConfig(targets: AnalyticsTargets(generateDocs: true));

      expect(cli.resolveDocsFlag(results, config), isFalse);
    });

    test('resolveExportsFlag defaults to config exports', () {
      final results = parser.parse(const <String>[]);
      const config =
          AnalyticsConfig(targets: AnalyticsTargets(generateCsv: true));

      expect(cli.resolveExportsFlag(results, config), isTrue);
    });

    test('resolveExportsFlag respects CLI --no-exports', () {
      final results = parser.parse(const <String>['--no-exports']);
      const config =
          AnalyticsConfig(targets: AnalyticsTargets(generateCsv: true));

      expect(cli.resolveExportsFlag(results, config), isFalse);
    });
  });
}
