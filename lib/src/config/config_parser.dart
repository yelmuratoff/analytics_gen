import '../util/yaml_keys.dart';
import 'analytics_config.dart';
import 'naming_strategy.dart';

/// Parses [AnalyticsConfig] from YAML.
class ConfigParser {
  /// Default constructor
  const ConfigParser();

  /// Parses configuration from a YAML map.
  AnalyticsConfig parse(Map<dynamic, dynamic> yaml) {
    if (yaml.isEmpty) return const AnalyticsConfig();

    T cast<T>(dynamic value, String context) {
      // If T is nullable and value is null, "value is T" returns true.
      if (value is T) return value;
      throw FormatException(
          'Invalid configuration for "\\$context": Expected \$T but got \${value.runtimeType}');
    }

    Map<dynamic, dynamic> safeMap(dynamic map, String context) {
      if (map == null) return {};
      if (map is Map) return map;
      throw FormatException(
          'Invalid configuration for "\\$context": Expected Map but got \${map.runtimeType}');
    }

    final config = safeMap(yaml[YamlKeys.analyticsGen], YamlKeys.analyticsGen);
    final inputs = safeMap(config[YamlKeys.inputs], YamlKeys.inputs);
    final outputs = safeMap(config[YamlKeys.outputs], YamlKeys.outputs);
    final targets = safeMap(config[YamlKeys.targets], YamlKeys.targets);
    final rules = safeMap(config[YamlKeys.rules], YamlKeys.rules);

    T val<T>(Map map, String key, T defaultVal) {
      final v = map[key];
      if (v == null) return defaultVal;
      return cast<T>(v, key);
    }

    List<String> list(Map map, String key, List<String> defaultVal) {
      final v = map[key];
      if (v == null) return defaultVal;
      if (v is! List) {
        throw FormatException(
            'Invalid configuration for "\\$key": Expected List but got \${v.runtimeType}');
      }
      return v.map((e) => e.toString()).toList();
    }

    return AnalyticsConfig(
      inputs: AnalyticsInputs(
        eventsPath: val(
          inputs,
          YamlKeys.events,
          val(config, YamlKeys.eventsPath, 'events'),
        ),
        contexts: list(
          inputs,
          YamlKeys.contexts,
          list(config, YamlKeys.contexts, []),
        ),
        sharedParameters: list(
          inputs,
          YamlKeys.sharedParameters,
          list(config, YamlKeys.sharedParameters, []),
        ),
        imports: list(
          inputs,
          YamlKeys.imports,
          list(config, YamlKeys.imports, []),
        ),
      ),
      outputs: AnalyticsOutputs(
        dartPath: val(
          outputs,
          YamlKeys.dart,
          val(config, YamlKeys.outputPath, 'lib/src/analytics/generated'),
        ),
        docsPath: val(
          outputs,
          YamlKeys.docs,
          val(config, YamlKeys.docsPath, null),
        ),
        exportsPath: val(
          outputs,
          YamlKeys.exports,
          val(config, YamlKeys.exportsPath, null),
        ),
      ),
      targets: AnalyticsTargets(
        generateCsv: val(
          targets,
          YamlKeys.csv,
          val(config, YamlKeys.generateCsv, false),
        ),
        generateJson: val(
          targets,
          YamlKeys.json,
          val(config, YamlKeys.generateJson, false),
        ),
        generateSql: val(
          targets,
          YamlKeys.sql,
          val(config, YamlKeys.generateSql, false),
        ),
        generateDocs: val(
          targets,
          YamlKeys.docs,
          val(config, YamlKeys.generateDocs, false),
        ),
        generatePlan: val(
          targets,
          YamlKeys.plan,
          val(config, YamlKeys.generatePlan, true),
        ),
        generateTestMatchers: val(
          targets,
          YamlKeys.testMatchers,
          val(config, YamlKeys.generateTestMatchers, false),
        ),
      ),
      rules: AnalyticsRules(
        includeEventDescription: val(
          rules,
          YamlKeys.includeEventDescription,
          val(config, YamlKeys.includeEventDescription, false),
        ),
        strictEventNames: val(
          rules,
          YamlKeys.strictEventNames,
          val(config, YamlKeys.strictEventNames, true),
        ),
        enforceCentrallyDefinedParameters: val(
          rules,
          YamlKeys.enforceCentrallyDefinedParameters,
          val(config, YamlKeys.enforceCentrallyDefinedParameters, false),
        ),
        preventEventParameterDuplicates: val(
          rules,
          YamlKeys.preventEventParameterDuplicates,
          val(config, YamlKeys.preventEventParameterDuplicates, false),
        ),
      ),
      naming: NamingStrategy.fromYaml(config[YamlKeys.naming] as Map?),
    );
  }
}
