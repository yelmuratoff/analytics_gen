import '../util/yaml_keys.dart';
import 'analytics_config.dart';
import 'naming_strategy.dart';

/// Parses [AnalyticsConfig] from YAML.
class ConfigParser {
  /// Default constructor
  const ConfigParser();

  /// Parses configuration from a YAML map.
  AnalyticsConfig parse(Map<dynamic, dynamic> yaml) {
    const defaults = AnalyticsConfig();
    if (yaml.isEmpty) return defaults;

    T cast<T>(dynamic value, String context) {
      // If T is nullable and value is null, "value is T" returns true.
      if (value is T) return value;
      throw FormatException(
        'Invalid configuration for "$context": expected $T but got ${value.runtimeType}',
      );
    }

    Map<dynamic, dynamic> safeMap(dynamic map, String context) {
      if (map == null) return {};
      if (map is Map) return map;
      throw FormatException(
        'Invalid configuration for "$context": expected Map but got ${map.runtimeType}',
      );
    }

    final config = safeMap(yaml[YamlKeys.analyticsGen], YamlKeys.analyticsGen);
    final inputs = safeMap(config[YamlKeys.inputs], YamlKeys.inputs);
    final outputs = safeMap(config[YamlKeys.outputs], YamlKeys.outputs);
    final targets = safeMap(config[YamlKeys.targets], YamlKeys.targets);
    final rules = safeMap(config[YamlKeys.rules], YamlKeys.rules);
    final metaConfig = safeMap(config[YamlKeys.meta], YamlKeys.meta);

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
          'Invalid configuration for "$key": expected List but got ${v.runtimeType}',
        );
      }
      return v.map((e) => e.toString()).toList();
    }

    return AnalyticsConfig(
      inputs: AnalyticsInputs(
        eventsPath: val(
          inputs,
          YamlKeys.events,
          val(config, YamlKeys.eventsPath, defaults.inputs.eventsPath),
        ),
        contexts: list(
          inputs,
          YamlKeys.contexts,
          list(config, YamlKeys.contexts, defaults.inputs.contexts),
        ),
        sharedParameters: list(
          inputs,
          YamlKeys.sharedParameters,
          list(
            config,
            YamlKeys.sharedParameters,
            defaults.inputs.sharedParameters,
          ),
        ),
        imports: list(
          inputs,
          YamlKeys.imports,
          list(config, YamlKeys.imports, defaults.inputs.imports),
        ),
      ),
      outputs: AnalyticsOutputs(
        dartPath: val(
          outputs,
          YamlKeys.dart,
          val(config, YamlKeys.outputPath, defaults.outputs.dartPath),
        ),
        docsPath: val(
          outputs,
          YamlKeys.docs,
          val(config, YamlKeys.docsPath, defaults.outputs.docsPath),
        ),
        exportsPath: val(
          outputs,
          YamlKeys.exports,
          val(config, YamlKeys.exportsPath, defaults.outputs.exportsPath),
        ),
        studioPath: val(
          outputs,
          YamlKeys.studio,
          val(config, YamlKeys.studioPath, defaults.outputs.studioPath),
        ),
      ),
      targets: AnalyticsTargets(
        generateCsv: val(
          targets,
          YamlKeys.csv,
          val(config, YamlKeys.generateCsv, defaults.targets.generateCsv),
        ),
        generateJson: val(
          targets,
          YamlKeys.json,
          val(config, YamlKeys.generateJson, defaults.targets.generateJson),
        ),
        generateSql: val(
          targets,
          YamlKeys.sql,
          val(config, YamlKeys.generateSql, defaults.targets.generateSql),
        ),
        generateDocs: val(
          targets,
          YamlKeys.docs,
          val(config, YamlKeys.generateDocs, defaults.targets.generateDocs),
        ),
        generatePlan: val(
          targets,
          YamlKeys.plan,
          val(config, YamlKeys.generatePlan, defaults.targets.generatePlan),
        ),
        generateTestMatchers: val(
          targets,
          YamlKeys.testMatchers,
          val(
            config,
            YamlKeys.generateTestMatchers,
            defaults.targets.generateTestMatchers,
          ),
        ),
        generateStudio: val(
          targets,
          YamlKeys.studio,
          val(config, YamlKeys.generateStudio, defaults.targets.generateStudio),
        ),
      ),
      rules: AnalyticsRules(
        includeEventDescription: val(
          rules,
          YamlKeys.includeEventDescription,
          val(
            config,
            YamlKeys.includeEventDescription,
            defaults.rules.includeEventDescription,
          ),
        ),
        strictEventNames: val(
          rules,
          YamlKeys.strictEventNames,
          val(
            config,
            YamlKeys.strictEventNames,
            defaults.rules.strictEventNames,
          ),
        ),
        enforceCentrallyDefinedParameters: val(
          rules,
          YamlKeys.enforceCentrallyDefinedParameters,
          val(
            config,
            YamlKeys.enforceCentrallyDefinedParameters,
            defaults.rules.enforceCentrallyDefinedParameters,
          ),
        ),
        preventEventParameterDuplicates: val(
          rules,
          YamlKeys.preventEventParameterDuplicates,
          val(
            config,
            YamlKeys.preventEventParameterDuplicates,
            defaults.rules.preventEventParameterDuplicates,
          ),
        ),
      ),
      naming: NamingStrategy.fromYaml(
        safeMap(config[YamlKeys.naming], YamlKeys.naming),
      ),
      meta: AnalyticsMeta(
        autoTrackingCreationDate: val(
          metaConfig,
          YamlKeys.autoTrackingCreationDate,
          defaults.meta.autoTrackingCreationDate,
        ),
        includeMetaInParameters: val(
          metaConfig,
          YamlKeys.includeMetaInParameters,
          defaults.meta.includeMetaInParameters,
        ),
      ),
    );
  }
}
