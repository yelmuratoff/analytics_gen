import 'dart:io';

import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/generator/code_generator.dart';
import 'package:analytics_gen/src/parser/event_loader.dart';
import 'package:analytics_gen/src/parser/yaml_parser.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  group('CodeGenerator', () {
    late Directory tempProject;

    setUp(() {
      tempProject = Directory.systemTemp.createTempSync('analytics_gen_code_');
      // Create minimal project structure
      Directory(p.join(tempProject.path, 'lib')).createSync(recursive: true);
      Directory(p.join(tempProject.path, 'events')).createSync(recursive: true);
    });

    tearDown(() {
      if (tempProject.existsSync()) {
        tempProject.deleteSync(recursive: true);
      }
    });

    test('generates domain mixin and Analytics singleton', () async {
      final eventsFile = File(p.join(tempProject.path, 'events', 'auth.yaml'));
      await eventsFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: User logs in\n'
        '    deprecated: true\n'
        '    replacement: auth.login_v2\n'
        '    parameters:\n'
        '      method: string\n',
      );

      final config = AnalyticsConfig(
        eventsPath: 'events',
        outputPath: 'src/analytics/generated',
      );

      final logs = <String>[];
      final generator = CodeGenerator(
        config: config,
        projectRoot: tempProject.path,
        log: TestLogger(logs),
      );

      final loader = EventLoader(
        eventsPath: p.join(tempProject.path, config.eventsPath),
      );
      final sources = await loader.loadEventFiles();
      final parser = YamlParser();
      final domains = await parser.parseEvents(sources);

      await generator.generate(domains);

      final outputDir =
          Directory(p.join(tempProject.path, 'lib', config.outputPath));
      final eventsDir = Directory(p.join(outputDir.path, 'events'));
      final analyticsFile = File(p.join(outputDir.path, 'analytics.dart'));
      final authFile = File(p.join(eventsDir.path, 'auth_events.dart'));

      expect(eventsDir.existsSync(), isTrue);
      expect(analyticsFile.existsSync(), isTrue);
      expect(authFile.existsSync(), isTrue);

      final authContent = await authFile.readAsString();
      expect(authContent, contains('mixin AnalyticsAuth on AnalyticsBase'));
      expect(
        authContent,
        contains('void logAuthLogin({'),
      );
      expect(
        authContent,
        contains('logger.logEvent('),
      );
      expect(
        authContent,
        contains('@Deprecated('),
      );
      expect(
        authContent,
        contains('Use logAuthLoginV2 instead.'),
      );

      final analyticsContent = await analyticsFile.readAsString();
      expect(analyticsContent, contains('final class Analytics extends'));
      expect(analyticsContent, contains('Analytics.initialize'));
      expect(
        analyticsContent,
        contains('static const List<AnalyticsDomain> plan ='),
      );
      expect(analyticsContent, contains("name: 'auth'"));
      expect(analyticsContent, contains('AnalyticsParameter('));

      // Ensure logging used the injectable logger
      expect(
        logs.where((m) => m.contains('Starting analytics code generation')),
        isNotEmpty,
      );
    });

    test('guards parameters with allowed_values and preserves custom types',
        () async {
      final eventsFile = File(p.join(tempProject.path, 'events', 'auth.yaml'));
      await eventsFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: User logs in\n'
        '    parameters:\n'
        '      method:\n'
        '        type: string\n'
        '        allowed_values: [email, google]\n'
        '      timestamp: DateTime\n',
      );

      final config = AnalyticsConfig(
        eventsPath: 'events',
        outputPath: 'src/analytics/generated',
      );

      final generator = CodeGenerator(
        config: config,
        projectRoot: tempProject.path,
      );

      final loader = EventLoader(
        eventsPath: p.join(tempProject.path, config.eventsPath),
      );
      final sources = await loader.loadEventFiles();
      final parser = YamlParser(
        naming: config.naming,
        strictEventNames: config.strictEventNames,
      );
      final domains = await parser.parseEvents(sources);

      await generator.generate(domains);

      final authContent = await File(
        p.join(tempProject.path, 'lib', config.outputPath, 'events',
            'auth_events.dart'),
      ).readAsString();

      expect(
        authContent,
        contains('enum AnalyticsAuthLoginMethodEnum {'),
      );
      expect(
        authContent,
        contains("email('email'),"),
      );
      expect(
        authContent,
        contains("google('google');"),
      );
      expect(
        authContent,
        contains('required AnalyticsAuthLoginMethodEnum method,'),
      );
      expect(authContent, contains('required DateTime timestamp,'));
    });

    test('replaces placeholders in custom event_name with Dart interpolation',
        () async {
      final eventsFile =
          File(p.join(tempProject.path, 'events', 'screen.yaml'));
      await eventsFile.writeAsString(
        'screen:\n'
        '  view:\n'
        '    description: User views a screen\n'
        '    event_name: "Screen: {screen_name}"\n'
        '    parameters:\n'
        '      screen_name: string\n'
        '      previous_screen:\n'
        '        type: string?\n'
        '        description: Name of the previous screen\n'
        '      duration_ms:\n'
        '        type: int?\n'
        '        description: Time spent on previous screen in milliseconds\n',
      );

      final config = AnalyticsConfig(
        eventsPath: 'events',
        outputPath: 'src/analytics/generated',
        strictEventNames: false,
      );

      final generator = CodeGenerator(
        config: config,
        projectRoot: tempProject.path,
      );

      final loader = EventLoader(
        eventsPath: p.join(tempProject.path, config.eventsPath),
      );
      final sources = await loader.loadEventFiles();
      final parser = YamlParser(
        naming: config.naming,
        strictEventNames: config.strictEventNames,
      );
      final domains = await parser.parseEvents(sources);

      await generator.generate(domains);

      final screenContent = await File(
        p.join(tempProject.path, 'lib', config.outputPath, 'events',
            'screen_events.dart'),
      ).readAsString();

      // The event name should use Dart interpolation of the parameter.
      expect(screenContent, contains('name: "Screen: \${screenName}",'));
      // Parameters should keep their documentation and usage
      expect(screenContent, contains('required String screenName,'));
      expect(screenContent,
          contains('if (durationMs != null) "duration_ms": durationMs,'));
    });

    test('includes event description in parameters when enabled', () async {
      final eventsFile = File(p.join(tempProject.path, 'events', 'auth.yaml'));
      await eventsFile.writeAsString(
        'auth:\n'
        '  phone_login:\n'
        '    description: When user logs in via phone\n'
        '    parameters:\n'
        '      user_exists: bool?\n',
      );

      final config = AnalyticsConfig(
        eventsPath: 'events',
        outputPath: 'src/analytics/generated',
        includeEventDescription: true,
      );

      final generator = CodeGenerator(
        config: config,
        projectRoot: tempProject.path,
      );

      final loader = EventLoader(
        eventsPath: p.join(tempProject.path, config.eventsPath),
      );
      final sources = await loader.loadEventFiles();
      final parser = YamlParser();
      final domains = await parser.parseEvents(sources);

      await generator.generate(domains);

      final authContent = await File(
        p.join(tempProject.path, 'lib', config.outputPath, 'events',
            'auth_events.dart'),
      ).readAsString();

      expect(
        authContent,
        contains("'description': 'When user logs in via phone',"),
      );
      // Should still write the optional parameter
      expect(authContent,
          contains('if (userExists != null) "user_exists": userExists,'));
    });

    test('removes stale domain files before regenerating', () async {
      final eventsFile = File(p.join(tempProject.path, 'events', 'auth.yaml'));
      await eventsFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: User logs in\n',
      );

      final config = AnalyticsConfig(
        eventsPath: 'events',
        outputPath: 'src/analytics/generated',
      );

      final generator = CodeGenerator(
        config: config,
        projectRoot: tempProject.path,
      );

      final loader = EventLoader(
        eventsPath: p.join(tempProject.path, config.eventsPath),
      );
      final sources = await loader.loadEventFiles();
      final parser = YamlParser();
      final domains = await parser.parseEvents(sources);

      await generator.generate(domains);

      final eventsDir = Directory(
        p.join(tempProject.path, 'lib', config.outputPath, 'events'),
      );
      final staleFile = File(p.join(eventsDir.path, 'legacy_events.dart'));
      await staleFile.writeAsString('// stale domain');
      expect(staleFile.existsSync(), isTrue);

      await generator.generate(domains);

      expect(staleFile.existsSync(), isFalse);
      expect(
        File(p.join(eventsDir.path, 'auth_events.dart')).existsSync(),
        isTrue,
      );
    });

    test('skips generation and logs when no analytics events exist', () async {
      final logs = <String>[];
      final config = AnalyticsConfig(
        eventsPath: 'events',
        outputPath: 'src/analytics/generated',
      );
      final generator = CodeGenerator(
        config: config,
        projectRoot: tempProject.path,
        log: TestLogger(logs),
      );

      final loader = EventLoader(
        eventsPath: p.join(tempProject.path, config.eventsPath),
      );
      final sources = await loader.loadEventFiles();
      final parser = YamlParser();
      final domains = await parser.parseEvents(sources);

      await generator.generate(domains);

      final outputDir =
          Directory(p.join(tempProject.path, 'lib', config.outputPath));
      expect(outputDir.existsSync(), isFalse);
      expect(
        logs,
        contains(
            'No analytics events or properties found. Skipping generation.'),
      );
    });

    test(
        'documents parameter descriptions, optional checks, and replacement text',
        () async {
      final eventsFile =
          File(p.join(tempProject.path, 'events', 'billing.yaml'));
      await eventsFile.writeAsString(
        'billing:\n'
        '  purchase:\n'
        '    description: Completes a purchase\n'
        '    deprecated: true\n'
        '    replacement: legacy_event\n'
        '    parameters:\n'
        '      method:\n'
        "        type: 'string?'\n"
        '        description: Payment method description\n',
      );

      final config = AnalyticsConfig(
        eventsPath: 'events',
        outputPath: 'src/analytics/generated',
      );
      final generator = CodeGenerator(
        config: config,
        projectRoot: tempProject.path,
      );

      final loader = EventLoader(
        eventsPath: p.join(tempProject.path, config.eventsPath),
      );
      final sources = await loader.loadEventFiles();
      final parser = YamlParser();
      final domains = await parser.parseEvents(sources);

      await generator.generate(domains);

      final billingFile = File(
        p.join(tempProject.path, 'lib', config.outputPath, 'events',
            'billing_events.dart'),
      );
      final billingContent = await billingFile.readAsString();

      expect(billingContent, contains('Use legacy_event instead.'));
      expect(
        billingContent,
        contains('`method`: String? - Payment method description'),
      );
      expect(
        billingContent,
        contains('if (method != null) "method": method,'),
      );
    });

    test('generates multi-domain analytics class with plan metadata', () async {
      final eventsFile = File(p.join(tempProject.path, 'events', 'multi.yaml'));
      await eventsFile.writeAsString(
        '''
alpha:
  custom_event:
    description: Alpha event
    event_name: alpha.custom_event
    parameters:
      detail:
        type: string
        description: Detailed info
beta:
  first:
    description: Beta event
gamma:
  tap:
    description: Gamma event
delta:
  hit:
    description: Delta event
''',
      );

      final config = AnalyticsConfig(
        eventsPath: 'events',
        outputPath: 'src/analytics/generated',
      );
      final generator = CodeGenerator(
        config: config,
        projectRoot: tempProject.path,
      );

      final loader = EventLoader(
        eventsPath: p.join(tempProject.path, config.eventsPath),
      );
      final sources = await loader.loadEventFiles();
      final parser = YamlParser();
      final domains = await parser.parseEvents(sources);

      await generator.generate(domains);

      final analyticsFile = File(
        p.join(tempProject.path, 'lib', config.outputPath, 'analytics.dart'),
      );
      final analyticsContent = await analyticsFile.readAsString();

      expect(
        analyticsContent,
        contains(
          ' with\n'
          '    AnalyticsAlpha,\n'
          '    AnalyticsBeta,\n'
          '    AnalyticsDelta,\n'
          '    AnalyticsGamma',
        ),
      );
      expect(
        analyticsContent,
        contains("customEventName: 'alpha.custom_event'"),
      );
      expect(
        analyticsContent,
        contains("description: 'Detailed info'"),
      );
    });

    test('generates PII properties and sanitizeParams method', () async {
      final eventsFile = File(p.join(tempProject.path, 'events', 'auth.yaml'));
      await eventsFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: User logs in\n'
        '    parameters:\n'
        '      email:\n'
        '        type: string\n'
        '        meta:\n'
        '          pii: true\n'
        '      method: string\n',
      );

      final config = AnalyticsConfig(
        eventsPath: 'events',
        outputPath: 'src/analytics/generated',
      );

      final generator = CodeGenerator(
        config: config,
        projectRoot: tempProject.path,
      );

      final loader = EventLoader(
        eventsPath: p.join(tempProject.path, config.eventsPath),
      );
      final sources = await loader.loadEventFiles();
      final parser = YamlParser();
      final domains = await parser.parseEvents(sources);

      await generator.generate(domains);

      final analyticsFile = File(
        p.join(tempProject.path, 'lib', config.outputPath, 'analytics.dart'),
      );
      final analyticsContent = await analyticsFile.readAsString();

      expect(
        analyticsContent,
        contains('static const Map<String, Set<String>> _piiProperties = {'),
      );
      expect(
        analyticsContent,
        contains("'auth: login': {'email'},"),
      );
      expect(
        analyticsContent,
        contains('static Map<String, Object?> sanitizeParams('),
      );
      expect(
        analyticsContent,
        contains("sanitized[key] = '[REDACTED]';"),
      );
    });

    test('generates test file when enabled', () async {
      final eventsFile = File(p.join(tempProject.path, 'events', 'auth.yaml'));
      await eventsFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: User logs in\n'
        '    parameters:\n'
        '      method: string\n',
      );

      final config = AnalyticsConfig(
        eventsPath: 'events',
        outputPath: 'src/analytics/generated',
        generateTests: true,
      );

      final generator = CodeGenerator(
        config: config,
        projectRoot: tempProject.path,
      );

      final loader = EventLoader(
        eventsPath: p.join(tempProject.path, config.eventsPath),
      );
      final sources = await loader.loadEventFiles();
      final parser = YamlParser();
      final domains = await parser.parseEvents(sources);

      await generator.generate(domains);

      final testFile = File(
        p.join(tempProject.path, 'test', 'generated_plan_test.dart'),
      );
      expect(testFile.existsSync(), isTrue);
      final content = await testFile.readAsString();
      expect(content, contains('logAuthLogin constructs correctly'));
    });

    test('does not generate test file by default', () async {
      final eventsFile = File(p.join(tempProject.path, 'events', 'auth.yaml'));
      await eventsFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: User logs in\n'
        '    parameters:\n'
        '      method: string\n',
      );

      final config = AnalyticsConfig(
        eventsPath: 'events',
        outputPath: 'src/analytics/generated',
        // generateTests defaults to false
      );

      final generator = CodeGenerator(
        config: config,
        projectRoot: tempProject.path,
      );

      final loader = EventLoader(
        eventsPath: p.join(tempProject.path, config.eventsPath),
      );
      final sources = await loader.loadEventFiles();
      final parser = YamlParser();
      final domains = await parser.parseEvents(sources);

      await generator.generate(domains);

      final testFile = File(
        p.join(tempProject.path, 'test', 'generated_plan_test.dart'),
      );
      expect(testFile.existsSync(), isFalse);
    });

    test('generates regex validation code', () async {
      final eventsFile = File(p.join(tempProject.path, 'events', 'auth.yaml'));
      await eventsFile.writeAsString(
        'auth:\n'
        '  login:\n'
        '    description: User logs in\n'
        '    parameters:\n'
        '      email:\n'
        '        type: string\n'
        '        regex: "^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+\$"\n',
      );

      final config = AnalyticsConfig(
        eventsPath: 'events',
        outputPath: 'src/analytics/generated',
      );

      final generator = CodeGenerator(
        config: config,
        projectRoot: tempProject.path,
      );

      final loader = EventLoader(
        eventsPath: p.join(tempProject.path, config.eventsPath),
      );
      final sources = await loader.loadEventFiles();
      final parser = YamlParser();
      final domains = await parser.parseEvents(sources);

      await generator.generate(domains);

      final authContent = await File(
        p.join(tempProject.path, 'lib', config.outputPath, 'events',
            'auth_events.dart'),
      ).readAsString();

      expect(
        authContent,
        contains(
            "if (!RegExp(r'^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+\$').hasMatch(email)) {"),
      );
      expect(
        authContent,
        contains("throw ArgumentError.value("),
      );
      expect(
        authContent,
        contains("'must match regex ^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+\$',"),
      );
    });
  });
}
