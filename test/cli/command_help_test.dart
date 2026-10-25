import 'dart:async';

import 'package:analytics_gen/src/cli/arguments.dart';
import 'package:analytics_gen/src/cli/runner.dart';
import 'package:analytics_gen/src/pipeline/audit_runner.dart';
import 'package:analytics_gen/src/pipeline/studio_export_runner.dart';
import 'package:test/test.dart';

void main() {
  group('command help', () {
    Future<String> helpOf(Future<void> Function(List<String>) run) async {
      final printed = <String>[];
      await runZoned(
        () => run(const ['--help']),
        zoneSpecification: ZoneSpecification(
          print: (_, __, ___, line) => printed.add(line),
        ),
      );
      return printed.join('\n');
    }

    test('generate --help lists the generation options', () async {
      final help = await helpOf(AnalyticsGenRunner().run);

      expect(help, contains('Usage: dart run analytics_gen:generate'));
      expect(help, contains('--watch'));
      expect(help, contains('--validate-only'));
    });

    test('audit --help describes audit and only the options it reads',
        () async {
      final help = await helpOf(AuditRunner().run);

      expect(help, contains('Usage: dart run analytics_gen:audit'));
      expect(help, contains('--config'));
      expect(help, isNot(contains('--watch')));
      expect(help, isNot(contains('--docs')));
    });

    test('studio_export --help lists --output and no generation options',
        () async {
      final help = await helpOf(StudioExportRunner().run);

      expect(help, contains('Usage: dart run analytics_gen:studio_export'));
      expect(help, contains('--output'));
      expect(help, isNot(contains('--watch')));
    });
  });

  group('command parsers', () {
    test('audit rejects a generation-only flag', () {
      expect(
        () => createAuditArgParser().parse(const ['--watch']),
        throwsFormatException,
      );
    });

    test('studio_export rejects a generation-only flag', () {
      expect(
        () => createStudioExportArgParser().parse(const ['--docs']),
        throwsFormatException,
      );
    });
  });
}
