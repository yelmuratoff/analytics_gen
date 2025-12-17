import 'dart:io';

import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/generator/docs_generator.dart';
import 'package:analytics_gen/src/parser/event_loader.dart';
import 'package:analytics_gen/src/parser/yaml_parser.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../test_utils.dart';

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
        inputs: AnalyticsInputs(eventsPath: 'events'),
        outputs: AnalyticsOutputs(docsPath: 'docs/analytics_events.md'),
        targets: AnalyticsTargets(generateDocs: true),
      );

      final logs = <String>[];
      final generator = DocsGenerator(
        config: config,
        projectRoot: tempProject.path,
        log: TestLogger(logs),
      );

      final loader = EventLoader(
        eventsPath: p.join(tempProject.path, config.inputs.eventsPath),
      );
      final sources = await loader.loadEventFiles();
      final parser = YamlParser();
      final domains = await parser.parseEvents(sources);

      await generator.generate(domains);

      final docsFile = File(
        p.join(tempProject.path, config.outputs.docsPath!),
      );

      expect(docsFile.existsSync(), isTrue);

      final content = await docsFile.readAsString();
      expect(content, contains('# Analytics Events Documentation'));
      expect(content, contains('Fingerprint: `'));
      expect(
        content,
        contains('Domains: 1 | Events: 1 | Parameters: 1'),
      );
      expect(
        content,
        contains('| Event | Description | Status | Parameters |'),
      );
      expect(content, contains('Active'));
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

    test('orders domains and events deterministically', () async {
      final authFile = File(p.join(tempProject.path, 'events', 'z_auth.yaml'));
      await authFile.writeAsString(
        'auth:\n'
        '  z_event:\n'
        '    description: Last\n'
        '  a_event:\n'
        '    description: First\n',
      );

      final screenFile =
          File(p.join(tempProject.path, 'events', 'a_screen.yaml'));
      await screenFile.writeAsString(
        'screen:\n'
        '  view:\n'
        '    description: Screen view\n',
      );

      final config = AnalyticsConfig(
        inputs: AnalyticsInputs(eventsPath: 'events'),
        outputs: AnalyticsOutputs(docsPath: 'docs/analytics_events.md'),
        targets: AnalyticsTargets(generateDocs: true),
      );

      final generator = DocsGenerator(
        config: config,
        projectRoot: tempProject.path,
      );

      final loader = EventLoader(
        eventsPath: p.join(tempProject.path, config.inputs.eventsPath),
      );
      final sources = await loader.loadEventFiles();
      final parser = YamlParser();
      final domains = await parser.parseEvents(sources);

      await generator.generate(domains);

      final content = await File(
        p.join(tempProject.path, config.outputs.docsPath!),
      ).readAsString();

      final authIndex = content.indexOf('## auth');
      final screenIndex = content.indexOf('## screen');
      expect(authIndex, isNot(-1));
      expect(screenIndex, isNot(-1));
      expect(authIndex, lessThan(screenIndex));

      final firstEventIndex = content.indexOf('a_event');
      final lastEventIndex = content.indexOf('z_event');
      expect(firstEventIndex, lessThan(lastEventIndex));
    });

    test('skips documentation generation when no events exist', () async {
      final logs = <String>[];
      final config = AnalyticsConfig(
        inputs: AnalyticsInputs(eventsPath: 'events'),
      );
      final generator = DocsGenerator(
        config: config,
        projectRoot: tempProject.path,
        log: TestLogger(logs),
      );

      final loader = EventLoader(
        eventsPath: p.join(tempProject.path, config.inputs.eventsPath),
      );
      final sources = await loader.loadEventFiles();
      final parser = YamlParser();
      final domains = await parser.parseEvents(sources);

      await generator.generate(domains);

      expect(
        File(p.join(tempProject.path, 'analytics_docs.md')).existsSync(),
        isFalse,
      );
      expect(
        logs,
        contains(
          'No analytics events or properties found. Skipping documentation generation.',
        ),
      );
    });

    test('documents allowed values and map/list examples with custom path',
        () async {
      final eventsFile =
          File(p.join(tempProject.path, 'events', 'billing.yaml'));
      await eventsFile.writeAsString(
        'billing:\n'
        '  purchase:\n'
        '    description: Complex purchase\n'
        '    parameters:\n'
        '      type_option:\n'
        '        type: string\n'
        '        description: Payment type\n'
        '        allowed_values: [email, manual]\n'
        '      attributes: map\n'
        '      items: list\n',
      );

      final config = AnalyticsConfig(
        inputs: AnalyticsInputs(eventsPath: 'events'),
        outputs: AnalyticsOutputs(docsPath: 'docs/custom_documentation.md'),
        targets: AnalyticsTargets(generateDocs: true),
      );
      final logs = <String>[];

      final generator = DocsGenerator(
        config: config,
        projectRoot: tempProject.path,
        log: TestLogger(logs),
      );

      final loader = EventLoader(
        eventsPath: p.join(tempProject.path, config.inputs.eventsPath),
      );
      final sources = await loader.loadEventFiles();
      final parser = YamlParser();
      final domains = await parser.parseEvents(sources);

      await generator.generate(domains);

      final docsFile = File(p.join(tempProject.path, config.outputs.docsPath!));
      expect(docsFile.existsSync(), isTrue);

      final content = await docsFile.readAsString();
      expect(content, contains('(allowed: email, manual)'));
      expect(content, contains("{'key': 'value'}"));
      expect(content, contains("['item1', 'item2']"));
      expect(content, contains('Analytics.instance.logBillingPurchase('));
      expect(
        logs.join('\n'),
        contains('✓ Generated analytics documentation at:'),
      );
    });

    test('falls back to default analytics_docs.md when docsPath omitted',
        () async {
      final eventsFile = File(p.join(tempProject.path, 'events', 'auth.yaml'));
      await eventsFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: Default docs path\n'
        '    parameters: {}\n',
      );

      final config = AnalyticsConfig(
        inputs: AnalyticsInputs(eventsPath: 'events'),
        targets: AnalyticsTargets(generateDocs: true),
      );

      final generator = DocsGenerator(
        config: config,
        projectRoot: tempProject.path,
      );

      final loader = EventLoader(
        eventsPath: p.join(tempProject.path, config.inputs.eventsPath),
      );
      final sources = await loader.loadEventFiles();
      final parser = YamlParser();
      final domains = await parser.parseEvents(sources);

      await generator.generate(domains);

      final defaultPath = p.join(tempProject.path, 'analytics_docs.md');
      expect(File(defaultPath).existsSync(), isTrue);

      final content = await File(defaultPath).readAsString();
      expect(content, contains('# Analytics Events Documentation'));
    });

    test('escapes markdown table cells with pipes and newlines', () async {
      final eventsFile =
          File(p.join(tempProject.path, 'events', 'purchase.yaml'));
      await eventsFile.writeAsString(
        'purchase:\n'
        '  refund:\n'
        '    description: Contains | pipe\n'
        '    parameters:\n'
        '      reason:\n'
        '        type: string\n'
        '        description: |\n'
        '          first line\n'
        '          second line\n',
      );

      final config = AnalyticsConfig(
        inputs: AnalyticsInputs(eventsPath: 'events'),
        outputs: AnalyticsOutputs(docsPath: 'docs/analytics_events.md'),
        targets: AnalyticsTargets(generateDocs: true),
      );

      final generator = DocsGenerator(
        config: config,
        projectRoot: tempProject.path,
      );

      final loader = EventLoader(
        eventsPath: p.join(tempProject.path, config.inputs.eventsPath),
      );
      final sources = await loader.loadEventFiles();
      final parser = YamlParser();
      final domains = await parser.parseEvents(sources);

      await generator.generate(domains);

      final content = await File(
        p.join(tempProject.path, config.outputs.docsPath!),
      ).readAsString();

      expect(content, contains('purchase_refund'));
      expect(content, contains('Contains \\| pipe'));
      expect(content, contains('first line<br>second line'));
    });

    test('marks deprecated events and shows replacements in status column',
        () async {
      final eventsFile = File(p.join(tempProject.path, 'events', 'auth.yaml'));
      await eventsFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: User logs in\n'
        '    deprecated: true\n'
        '    replacement: auth.login_v2\n'
        '    parameters: {}\n',
      );

      final config = AnalyticsConfig(
        inputs: AnalyticsInputs(eventsPath: 'events'),
        outputs: AnalyticsOutputs(docsPath: 'docs/analytics_events.md'),
        targets: AnalyticsTargets(generateDocs: true),
      );

      final generator = DocsGenerator(
        config: config,
        projectRoot: tempProject.path,
      );

      final loader = EventLoader(
        eventsPath: p.join(tempProject.path, config.inputs.eventsPath),
      );
      final sources = await loader.loadEventFiles();
      final parser = YamlParser();
      final domains = await parser.parseEvents(sources);

      await generator.generate(domains);

      final content = await File(
        p.join(tempProject.path, config.outputs.docsPath!),
      ).readAsString();

      expect(content, contains('**Deprecated** -> `auth.login_v2`'));
    });

    test('produces identical output on repeated runs', () async {
      final eventsFile = File(p.join(tempProject.path, 'events', 'auth.yaml'));
      await eventsFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: User logs in\n'
        '    parameters:\n'
        '      method:\n'
        '        type: string\n',
      );

      final config = AnalyticsConfig(
        inputs: AnalyticsInputs(eventsPath: 'events'),
        outputs: AnalyticsOutputs(docsPath: 'docs/analytics_events.md'),
        targets: AnalyticsTargets(generateDocs: true),
      );

      final generator = DocsGenerator(
        config: config,
        projectRoot: tempProject.path,
      );

      final loader = EventLoader(
        eventsPath: p.join(tempProject.path, config.inputs.eventsPath),
      );
      final sources = await loader.loadEventFiles();
      final parser = YamlParser();
      final domains = await parser.parseEvents(sources);

      await generator.generate(domains);
      final firstRun = await File(
        p.join(tempProject.path, config.outputs.docsPath!),
      ).readAsString();

      await Future<void>.delayed(const Duration(milliseconds: 5));

      await generator.generate(domains);
      final secondRun = await File(
        p.join(tempProject.path, config.outputs.docsPath!),
      ).readAsString();

      expect(secondRun, equals(firstRun));
    });

    test('documents parameter and event metadata', () async {
      final eventsFile = File(p.join(tempProject.path, 'events', 'auth.yaml'));
      await eventsFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: User logs in\n'
        '    meta:\n'
        '      owner: auth-team\n'
        '      pii: false\n'
        '    parameters:\n'
        '      method:\n'
        '        type: string\n'
        '        description: Login method\n'
        '        meta:\n'
        '          pii: true\n'
        '          source: user_input\n',
      );

      final config = AnalyticsConfig(
        inputs: AnalyticsInputs(eventsPath: 'events'),
        outputs: AnalyticsOutputs(docsPath: 'docs/analytics_events.md'),
        targets: AnalyticsTargets(generateDocs: true),
      );

      final generator = DocsGenerator(
        config: config,
        projectRoot: tempProject.path,
      );

      final loader = EventLoader(
        eventsPath: p.join(tempProject.path, config.inputs.eventsPath),
      );
      final sources = await loader.loadEventFiles();
      final parser = YamlParser();
      final domains = await parser.parseEvents(sources);

      await generator.generate(domains);

      final content = await File(
        p.join(tempProject.path, config.outputs.docsPath!),
      ).readAsString();

      // Check parameter metadata in table
      expect(content, contains('[pii: true, source: user_input]'));
      // Check event metadata in table
      expect(content, contains('**owner**: auth-team<br>**pii**: false'));
    });

    test('documents context properties with metadata and allowed values',
        () async {
      final contextFile =
          File(p.join(tempProject.path, 'events', 'user_properties.yaml'));
      await contextFile.writeAsString(
        'user_properties:\n'
        '  role:\n'
        '    type: string\n'
        '    description: User role\n'
        '    allowed_values: [admin, viewer, editor]\n'
        '    meta:\n'
        '      pii: false\n'
        '      required: true\n'
        '  theme:\n'
        '    type: string\n'
        '    description: UI theme\n'
        '    meta:\n'
        '      default: light\n',
      );

      final config = AnalyticsConfig(
        inputs: AnalyticsInputs(
          eventsPath: 'events',
          contexts: ['events/user_properties.yaml'],
        ),
        outputs: AnalyticsOutputs(docsPath: 'docs/analytics_events.md'),
        targets: AnalyticsTargets(generateDocs: true),
      );

      final generator = DocsGenerator(
        config: config,
        projectRoot: tempProject.path,
      );

      final loader = EventLoader(
        eventsPath: p.join(tempProject.path, config.inputs.eventsPath),
        contextFiles: config.inputs.contexts
            .map((c) => p.join(tempProject.path, c))
            .toList(),
      );
      final sources = await loader.loadEventFiles();
      final contextSources = await loader.loadContextFiles();
      final parser = YamlParser();
      final domains = await parser.parseEvents(sources);
      final contexts = await parser.parseContexts(contextSources);

      await generator.generate(domains, contexts: contexts);

      final content = await File(
        p.join(tempProject.path, config.outputs.docsPath!),
      ).readAsString();

      // Check context title generation (tests _getContextTitle)
      expect(content, contains('## User Properties'));

      // Check allowed values in properties table
      expect(content, contains('admin, viewer, editor'));

      // Check property metadata
      expect(content, contains('**pii**: false<br>**required**: true'));
      expect(content, contains('**default**: light'));
    });

    test('uses custom context title for known contexts', () async {
      final userPropsFile =
          File(p.join(tempProject.path, 'events', 'user_properties.yaml'));
      await userPropsFile.writeAsString(
        'user_properties:\n'
        '  id:\n'
        '    type: string\n',
      );

      final globalFile =
          File(p.join(tempProject.path, 'events', 'global_context.yaml'));
      await globalFile.writeAsString(
        'global_context:\n'
        '  version:\n'
        '    type: string\n',
      );

      final customFile =
          File(p.join(tempProject.path, 'events', 'custom_props.yaml'));
      await customFile.writeAsString(
        'custom_props:\n'
        '  setting:\n'
        '    type: string\n',
      );

      final config = AnalyticsConfig(
        inputs: AnalyticsInputs(
          eventsPath: 'events',
          contexts: [
            'events/user_properties.yaml',
            'events/global_context.yaml',
            'events/custom_props.yaml',
          ],
        ),
        outputs: AnalyticsOutputs(docsPath: 'docs/analytics_events.md'),
        targets: AnalyticsTargets(generateDocs: true),
      );

      final generator = DocsGenerator(
        config: config,
        projectRoot: tempProject.path,
      );

      final loader = EventLoader(
        eventsPath: p.join(tempProject.path, config.inputs.eventsPath),
        contextFiles: config.inputs.contexts
            .map((c) => p.join(tempProject.path, c))
            .toList(),
      );
      final sources = await loader.loadEventFiles();
      final contextSources = await loader.loadContextFiles();
      final parser = YamlParser();
      final domains = await parser.parseEvents(sources);
      final contexts = await parser.parseContexts(contextSources);

      await generator.generate(domains, contexts: contexts);

      final content = await File(
        p.join(tempProject.path, config.outputs.docsPath!),
      ).readAsString();

      // Known contexts get special titles
      expect(content, contains('## User Properties'));
      expect(content, contains('## Global Context'));
      // Custom context gets PascalCase title
      expect(content, contains('## CustomProps'));
    });
  });
}
