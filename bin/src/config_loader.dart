import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'package:analytics_gen/src/config/analytics_config.dart';

Future<AnalyticsConfig> loadAnalyticsConfig(
  String projectRoot,
  String configPath,
) async {
  final configFile = File(path.join(projectRoot, configPath));
  if (!configFile.existsSync()) {
    _printDefaultConfigReminder(configPath);
    return AnalyticsConfig.defaultConfig;
  }

  final content = await configFile.readAsString();
  final yaml = loadYaml(content) as Map;
  return AnalyticsConfig.fromYaml(yaml);
}

void _printDefaultConfigReminder(String configPath) {
  print('No config file found at $configPath, using defaults');
  print('');
  print('Tip: Create an analytics_gen.yaml file to customize paths:');
  print('');
  print('analytics_gen:');
  print('  events_path: events');
  print('  output_path: src/analytics/generated');
  print('  docs_path: docs/analytics_events.md');
  print('  exports_path: assets/generated');
  print('  generate_docs: true');
  print('  generate_csv: true');
  print('  generate_json: true');
  print('  generate_sql: true');
  print('  generate_plan: true');
  print('');
}
