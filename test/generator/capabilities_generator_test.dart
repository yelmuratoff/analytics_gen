import 'dart:io';

import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/generator/code_generator.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late String projectRoot;
  late AnalyticsConfig config;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('analytics_gen_test_');
    projectRoot = tempDir.path;
    config = AnalyticsConfig(
      eventsPath: 'events',
      outputPath: 'src/analytics',
    );
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test('generate creates user_properties.dart and updates analytics.dart',
      () async {
    final generator = CodeGenerator(
      config: config,
      projectRoot: projectRoot,
    );

    final userProperties = [
      AnalyticsParameter(
        name: 'user_role',
        type: 'String',
        isNullable: false,
        allowedValues: ['admin', 'user'],
        description: 'User role',
      ),
    ];

    await generator.generate({}, contexts: {'user_properties': userProperties});

    final outputDir = path.join(projectRoot, 'lib', config.outputPath);
    final userPropsFile =
        File(path.join(outputDir, 'contexts', 'user_properties_context.dart'));
    final analyticsFile = File(path.join(outputDir, 'analytics.dart'));

    expect(userPropsFile.existsSync(), isTrue);
    expect(analyticsFile.existsSync(), isTrue);

    final userPropsContent = userPropsFile.readAsStringSync();
    expect(userPropsContent, contains('class UserPropertiesCapability'));
    expect(userPropsContent, contains('mixin AnalyticsUserProperties'));
    expect(userPropsContent,
        contains('void setUserPropertiesUserRole(String value)'));
    expect(
        userPropsContent,
        contains(
            "capability(userPropertiesKey)?.setUserPropertiesProperty('user_role', value)"));

    final analyticsContent = analyticsFile.readAsStringSync();
    expect(analyticsContent,
        contains("import 'contexts/user_properties_context.dart';"));
    expect(analyticsContent, contains('with AnalyticsUserProperties'));
  });

  test('generate does not create user_properties.dart if empty', () async {
    final generator = CodeGenerator(
      config: config,
      projectRoot: projectRoot,
    );

    await generator.generate({}, contexts: {'user_properties': []});

    final outputDir = path.join(projectRoot, 'lib', config.outputPath);
    final userPropsFile =
        File(path.join(outputDir, 'contexts', 'user_properties_context.dart'));
    final analyticsFile = File(path.join(outputDir, 'analytics.dart'));

    expect(userPropsFile.existsSync(), isFalse);
    expect(analyticsFile.existsSync(), isFalse);
  });

  test('generate creates global_context.dart and updates analytics.dart',
      () async {
    final generator = CodeGenerator(
      config: config,
      projectRoot: projectRoot,
    );

    final globalContext = [
      AnalyticsParameter(
        name: 'app_version',
        type: 'String',
        isNullable: false,
        description: 'Application version',
      ),
    ];

    await generator.generate({}, contexts: {'global_context': globalContext});

    final outputDir = path.join(projectRoot, 'lib', config.outputPath);
    final contextFile =
        File(path.join(outputDir, 'contexts', 'global_context_context.dart'));
    final analyticsFile = File(path.join(outputDir, 'analytics.dart'));

    expect(contextFile.existsSync(), isTrue);
    expect(analyticsFile.existsSync(), isTrue);

    final contextContent = contextFile.readAsStringSync();
    expect(contextContent, contains('class GlobalContextCapability'));
    expect(contextContent, contains('mixin AnalyticsGlobalContext'));
    expect(contextContent,
        contains('void setGlobalContextAppVersion(String value)'));
    expect(
        contextContent,
        contains(
            "capability(globalContextKey)?.setGlobalContextProperty('app_version', value)"));

    final analyticsContent = analyticsFile.readAsStringSync();
    expect(analyticsContent,
        contains("import 'contexts/global_context_context.dart';"));
    expect(analyticsContent, contains('with AnalyticsGlobalContext'));
  });

  test('generate creates both files when both are present', () async {
    final generator = CodeGenerator(
      config: config,
      projectRoot: projectRoot,
    );

    final userProperties = [
      AnalyticsParameter(
        name: 'role',
        type: 'String',
        isNullable: false,
      ),
    ];
    final globalContext = [
      AnalyticsParameter(
        name: 'version',
        type: 'String',
        isNullable: false,
      ),
    ];

    await generator.generate(
      {},
      contexts: {
        'user_properties': userProperties,
        'global_context': globalContext,
      },
    );

    final outputDir = path.join(projectRoot, 'lib', config.outputPath);
    final userPropsFile =
        File(path.join(outputDir, 'contexts', 'user_properties_context.dart'));
    final contextFile =
        File(path.join(outputDir, 'contexts', 'global_context_context.dart'));
    final analyticsFile = File(path.join(outputDir, 'analytics.dart'));

    expect(userPropsFile.existsSync(), isTrue);
    expect(contextFile.existsSync(), isTrue);
    expect(analyticsFile.existsSync(), isTrue);

    final analyticsContent = analyticsFile.readAsStringSync();
    expect(analyticsContent,
        contains("import 'contexts/user_properties_context.dart';"));
    expect(analyticsContent,
        contains("import 'contexts/global_context_context.dart';"));
    expect(analyticsContent,
        contains('with AnalyticsGlobalContext, AnalyticsUserProperties'));
  });

  test('generate creates generic context file and updates analytics.dart',
      () async {
    final generator = CodeGenerator(
      config: config,
      projectRoot: projectRoot,
    );

    final contexts = {
      'device': [
        AnalyticsParameter(
          name: 'os_version',
          type: 'String',
          isNullable: false,
        ),
      ],
    };

    await generator.generate({}, contexts: contexts);

    final outputDir = path.join(projectRoot, 'lib', config.outputPath);
    final contextFile =
        File(path.join(outputDir, 'contexts', 'device_context.dart'));
    final analyticsFile = File(path.join(outputDir, 'analytics.dart'));

    expect(contextFile.existsSync(), isTrue);
    expect(analyticsFile.existsSync(), isTrue);

    final contextContent = contextFile.readAsStringSync();
    expect(contextContent, contains('class DeviceCapability'));
    expect(contextContent, contains('mixin AnalyticsDevice'));
    expect(contextContent, contains('void setDeviceOsVersion(String value)'));
    expect(
        contextContent,
        contains(
            "capability(deviceKey)?.setDeviceProperty('os_version', value)"));

    final analyticsContent = analyticsFile.readAsStringSync();
    expect(
        analyticsContent, contains("import 'contexts/device_context.dart';"));
    expect(analyticsContent, contains('with AnalyticsDevice'));
  });
}
