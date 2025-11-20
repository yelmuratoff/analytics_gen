import 'package:yaml/yaml.dart';

import '../config/naming_strategy.dart';
import '../core/exceptions.dart';
import '../models/analytics_event.dart';
import '../util/string_utils.dart';

/// Helper class responsible for parsing analytics parameters from YAML.
class ParameterParser {
  final NamingStrategy naming;

  const ParameterParser(this.naming);

  /// Parses a list of parameters from a YAML map.
  List<AnalyticsParameter> parseParameters(
    YamlMap parametersYaml, {
    required String domainName,
    required String eventName,
    required String filePath,
  }) {
    final parameters = <AnalyticsParameter>[];
    final seenRawNames = <String>{};
    final seenAnalyticsNames = <String>{};
    final camelNameToOriginal = <String, String>{};

    final sortedEntries = parametersYaml.entries.toList()
      ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));

    for (final entry in sortedEntries) {
      final rawName = entry.key.toString();
      if (!seenRawNames.add(rawName)) {
        throw AnalyticsParseException(
          'Duplicate parameter "$rawName" found in $domainName.$eventName.',
          filePath: filePath,
        );
      }

      final paramValue = entry.value;
      final identifierOverride =
          paramValue is YamlMap ? paramValue['identifier'] as String? : null;
      final wireNameOverride =
          paramValue is YamlMap ? paramValue['param_name'] as String? : null;

      final codeIdentifier = identifierOverride ?? rawName;
      final analyticsName = wireNameOverride ?? rawName;

      if (codeIdentifier.isEmpty) {
        throw AnalyticsParseException(
          'Parameter "$rawName" in $domainName.$eventName must declare a '
          'non-empty identifier.',
          filePath: filePath,
        );
      }

      if (!naming.isValidParameterIdentifier(codeIdentifier)) {
        throw AnalyticsParseException(
          'Parameter identifier "$codeIdentifier" in $domainName.$eventName '
          'violates the configured naming strategy. Update '
          'analytics_gen.naming.enforce_snake_case_parameters or define a '
          'different `identifier`.',
          filePath: filePath,
        );
      }

      if (!seenAnalyticsNames.add(analyticsName)) {
        throw AnalyticsParseException(
          'Duplicate analytics parameter "$analyticsName" found in '
          '$domainName.$eventName.',
          filePath: filePath,
        );
      }

      final camelParamName = StringUtils.toCamelCase(codeIdentifier);
      final existingParam = camelNameToOriginal[camelParamName];
      if (existingParam != null) {
        throw AnalyticsParseException(
          'Parameter identifier "$codeIdentifier" in $domainName.$eventName '
          'conflicts with "$existingParam" after camelCase normalization.',
          filePath: filePath,
        );
      }
      camelNameToOriginal[camelParamName] = codeIdentifier;

      String paramType;
      String? description;
      List<String>? allowedValues;
      String? regex;
      int? minLength;
      int? maxLength;
      num? min;
      num? max;
      Map<String, Object?> meta = const {};

      if (paramValue is YamlMap) {
        // Complex parameter with 'type' and/or 'description'
        description = paramValue['description'] as String?;
        meta = _parseMeta(paramValue['meta'], filePath);

        // Validation rules
        regex = paramValue['regex'] as String?;
        minLength = paramValue['min_length'] as int?;
        maxLength = paramValue['max_length'] as int?;
        min = paramValue['min'] as num?;
        max = paramValue['max'] as num?;

        // Check if 'type' key exists explicitly
        if (paramValue.containsKey('type')) {
          paramType = paramValue['type'].toString();
        } else {
          // Fallback: Find type key (anything except 'description')
          final typeKey = paramValue.keys
              .where(
                (k) =>
                    k.toString() != 'description' &&
                    k.toString() != 'allowed_values' &&
                    k.toString() != 'identifier' &&
                    k.toString() != 'param_name' &&
                    k.toString() != 'meta',
              )
              .firstOrNull;
          paramType = typeKey?.toString() ?? 'dynamic';
        }

        final rawAllowed = paramValue['allowed_values'];
        if (rawAllowed != null) {
          if (rawAllowed is! YamlList) {
            throw AnalyticsParseException(
              'allowed_values for parameter "$rawName" must be a list.',
              filePath: filePath,
            );
          }
          allowedValues = rawAllowed.map((e) => e.toString()).toList();
        }
      } else {
        // Simple parameter (just type)
        paramType = paramValue.toString();
      }

      // Check if nullable
      final isNullable = paramType.endsWith('?');
      if (isNullable) {
        paramType = paramType.substring(0, paramType.length - 1);
      }

      parameters.add(
        AnalyticsParameter(
          name: analyticsName,
          codeName: codeIdentifier,
          type: paramType,
          isNullable: isNullable,
          description: description,
          allowedValues: allowedValues,
          regex: regex,
          minLength: minLength,
          maxLength: maxLength,
          min: min,
          max: max,
          meta: meta,
        ),
      );
    }

    return parameters;
  }

  Map<String, Object?> _parseMeta(dynamic metaYaml, String filePath) {
    if (metaYaml == null) return const {};
    if (metaYaml is! YamlMap) {
      throw AnalyticsParseException(
        'The "meta" field must be a map.',
        filePath: filePath,
      );
    }
    // Convert YamlMap to Map<String, Object?>
    return metaYaml.map((key, value) => MapEntry(key.toString(), value));
  }
}
