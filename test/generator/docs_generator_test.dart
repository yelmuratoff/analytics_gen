import 'dart:io';

import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/generator/docs_generator.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('DocsGenerator', () {
    late Directory tempProject;

    setUp(() {
      tempProject = Directory.systemTemp.createTempSync('analytics_gen_docs_');
      Directory(p.join(tempProject.path, 'events')).createSync(recursive: true);
    });

    tearDown(() {
      if (tempProject.existsSync()) {
        tempProject.deleteSync(recursive: true);
      }
    });

    test('generates markdown with domain and event table', () async {
      final eventsFile = File(p.join(tempProject.path, 'events', 'auth.yaml'));
      await eventsFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: User logs in\n'
        '    parameters:\n'
        '      method:\n'
        '        type: string\n'
        '        description: Login method\n',
      );

      final config = AnalyticsConfig(
        eventsPath: 'events',
        docsPath: 'docs/analytics_events.md',
        generateDocs: true,
      );

      final logs = <String>[];
      final generator = DocsGenerator(
        config: config,
        projectRoot: tempProject.path,
        log: logs.add,
      );

      await generator.generate();

      final docsFile = File(
        p.join(tempProject.path, config.docsPath!),
      );

      expect(docsFile.existsSync(), isTrue);

      final content = await docsFile.readAsString();
      expect(content, contains('# Analytics Events Documentation'));
      expect(content, contains('## auth'));
      expect(content, contains('login'));
      expect(content, contains('User logs in'));
      expect(content, contains('method'));
      expect(content, contains('Login method'));

      // Usage example should reference the generated method name
      expect(content, contains('Analytics.instance.logAuthLogin('));

      // Ensure logging goes through provided logger
      expect(
        logs.where(
          (m) => m.contains('Starting analytics documentation generation'),
        ),
        isNotEmpty,
      );
    });
  });
}

