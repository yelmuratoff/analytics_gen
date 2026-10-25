import 'dart:io';

import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/config/config_parser.dart';
import 'package:analytics_gen/src/util/logger.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Loads the analytics configuration from the given path.
Future<AnalyticsConfig> loadAnalyticsConfig(
  String projectRoot,
  String configPath, {
  Logger? logger,
  ConfigParser? parser,
}) async {
  final log = logger ?? const ConsoleLogger();
  final configParser = parser ?? const ConfigParser();
  final configFile = File(path.join(projectRoot, configPath));
  if (!configFile.existsSync()) {
    _printDefaultConfigReminder(configPath, log);
    return AnalyticsConfig.defaultConfig;
  }

  final content = await configFile.readAsString();
  return switch (loadYaml(content)) {
    null => configParser.parse(const {}),
    final Map yaml => configParser.parse(yaml),
    final YamlList _ => throw FormatException(
        'Invalid configuration file "$configPath": '
        'expected a map but got a list',
      ),
    final other => throw FormatException(
        'Invalid configuration file "$configPath": '
        'expected a map but got "$other"',
      ),
  };
}

void _printDefaultConfigReminder(String configPath, Logger logger) {
  logger.info('No config file found at $configPath, using defaults');
  logger.info('');
  logger.info('Tip: Create an analytics_gen.yaml file to customize paths:');
  logger.info('');
  logger.info('analytics_gen:');
  logger.info('  inputs:');
  logger.info('    events: events');
  logger.info('  outputs:');
  logger.info('    dart: lib/src/analytics/generated');
  logger.info('    docs: docs/analytics_events.md');
  logger.info('    exports: assets/generated');
  logger.info('  targets:');
  logger.info('    docs: true');
  logger.info('    json: true');
  logger.info('    test_matchers: true');
  logger.info('');
}
