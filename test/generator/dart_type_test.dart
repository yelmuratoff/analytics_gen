import 'dart:io';

import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/generator/code_generator.dart';
import 'package:analytics_gen/src/parser/event_loader.dart';
import 'package:analytics_gen/src/parser/yaml_parser.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  group('CodeGenerator - dart_type', () {
    late Directory tempProject;

    setUp(() {
      tempProject =
          Directory.systemTemp.createTempSync('analytics_gen_dart_type_');
      // Create minimal project structure
      Directory(p.join(tempProject.path, 'lib')).createSync(recursive: true);
      Directory(p.join(tempProject.path, 'events')).createSync(recursive: true);
    });

    tearDown(() {
      if (tempProject.existsSync()) {
        tempProject.deleteSync(recursive: true);
      }
    });

    test(
        'generates method signature with custom Dart type and serializes using .name',
        () async {
      final eventsFile =
          File(p.join(tempProject.path, 'events', 'feature.yaml'));
      await eventsFile.writeAsString(
        'feature:\n'
        '  interact:\n'
        '    description: User interacts with a feature\n'
        '    parameters:\n'
        '      status:\n'
        '        dart_type: VerificationStatus\n'
        '      nullable_status:\n'
        '        dart_type: VerificationStatus?\n',
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

      final featureFile = File(
        p.join(tempProject.path, 'lib', config.outputPath, 'events',
            'feature_events.dart'),
      );

      expect(featureFile.existsSync(), isTrue);
      final content = await featureFile.readAsString();

      // Check method signature
      expect(content, contains('required VerificationStatus status,'));
      expect(content, contains('VerificationStatus? nullableStatus,'));

      // Check serialization in parameters map
      expect(content, contains('"status": status.name,'));
      expect(
          content,
          contains(
              'if (nullableStatus != null) "nullable_status": nullableStatus?.name,'));
    });

    test('generates dual-write call matching dart_type correctly', () async {
      final eventsFile =
          File(p.join(tempProject.path, 'events', 'feature.yaml'));
      await eventsFile.writeAsString(
        'feature:\n'
        '  primary:\n'
        '    parameters:\n'
        '      status:\n'
        '        dart_type: VerificationStatus\n'
        '    dual_write_to: [feature.secondary]\n'
        '  secondary:\n'
        '    parameters:\n'
        '      status:\n'
        '        dart_type: VerificationStatus\n',
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

      final featureFile = File(
        p.join(tempProject.path, 'lib', config.outputPath, 'events',
            'feature_events.dart'),
      );
      final content = await featureFile.readAsString();

      // Should verify that the method call passes the parameter directly (since types match)
      expect(
          content,
          contains(
              'logFeatureSecondary(status: status, parameters: parameters);'));
    });

    test('injects custom imports into generated file', () async {
      final eventsFile =
          File(p.join(tempProject.path, 'events', 'feature.yaml'));
      await eventsFile.writeAsString(
        'feature:\n'
        '  interact:\n'
        '    parameters:\n'
        '      status:\n'
        '        dart_type: VerificationStatus\n',
      );

      final config = AnalyticsConfig(
        eventsPath: 'events',
        outputPath: 'src/analytics/generated',
        imports: ['package:my_app/models.dart'],
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

      final featureFile = File(
        p.join(tempProject.path, 'lib', config.outputPath, 'events',
            'feature_events.dart'),
      );
      final content = await featureFile.readAsString();

      expect(content, contains("import 'package:my_app/models.dart';"));
    });

    test('injects local import from parameter definition', () async {
      final eventsFile =
          File(p.join(tempProject.path, 'events', 'feature.yaml'));
      await eventsFile.writeAsString(
        'feature:\n'
        '  interact:\n'
        '    parameters:\n'
        '      status:\n'
        '        dart_type: VerificationStatus\n'
        '        import: package:my_app/local_types.dart\n',
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

      final featureFile = File(
        p.join(tempProject.path, 'lib', config.outputPath, 'events',
            'feature_events.dart'),
      );
      final content = await featureFile.readAsString();

      expect(content, contains("import 'package:my_app/local_types.dart';"));
    });
  });
}
