import 'dart:io';

import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/config/config_parser.dart';
import 'package:analytics_gen/src/util/logger.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

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
  final yaml = loadYaml(content) as Map;
  return configParser.parse(yaml);
}

void _printDefaultConfigReminder(String configPath, Logger logger) {
  logger.info('No config file found at $configPath, using defaults');
  logger.info('');
  logger.info('Tip: Create an analytics_gen.yaml file to customize paths:');
  logger.info('');
  logger.info('analytics_gen:');
  logger.info('  events_path: events');
  logger.info('  output_path: src/analytics/generated');
  logger.info('  docs_path: docs/analytics_events.md');
  logger.info('  exports_path: assets/generated');
  logger.info('  generate_docs: true');
  logger.info('  generate_csv: true');
  logger.info('  generate_json: true');
  logger.info('  generate_sql: true');
  logger.info('  generate_plan: true');
  logger.info('');
}
