import 'package:collection/collection.dart';
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

import '../config/naming_strategy.dart';
import '../core/exceptions.dart';
import '../models/analytics_parameter.dart';
import '../util/string_utils.dart';
import 'json_value_normalizer.dart';

/// Parses analytics parameters from YAML.
final class ParameterParser {
  /// Parses a list of parameters from a YAML map.
  static List<AnalyticsParameter> parseParameters(
    YamlMap parametersYaml, {
    required String domainName,
    required String eventName,
    required String filePath,
    required NamingStrategy naming,
    Map<String, AnalyticsParameter> sharedParameters = const {},
    bool enforceCentrallyDefinedParameters = false,
    bool preventEventParameterDuplicates = false,
  }) {
    final parameters = <AnalyticsParameter>[];
    final seenRawNames = <String>{};
    final seenAnalyticsNames = <String>{};
    final camelNameToOriginal = <String, String>{};

    final sortedEntries = parametersYaml.nodes.entries.toList()
      ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));

    for (final entry in sortedEntries) {
      final keyNode = entry.key as YamlNode;
      final rawName = keyNode.toString();

      if (!seenRawNames.add(rawName)) {
        throw AnalyticsParseException(
          'Duplicate parameter "$rawName" found in $domainName.$eventName.',
          filePath: filePath,
          span: keyNode.span,
        );
      }

      final param = parseParameter(
        rawName,
        entry.value,
        domainName: domainName,
        eventName: eventName,
        filePath: filePath,
        naming: naming,
        sharedParameters: sharedParameters,
        enforceCentrallyDefinedParameters: enforceCentrallyDefinedParameters,
        preventEventParameterDuplicates: preventEventParameterDuplicates,
      );

      if (!seenAnalyticsNames.add(param.name)) {
        throw AnalyticsParseException(
          'Duplicate analytics parameter "${param.name}" found in '
          '$domainName.$eventName.',
          filePath: filePath,
          span: keyNode.span,
        );
      }

      final camelParamName = StringUtils.toCamelCase(param.codeName);
      final existingParam = camelNameToOriginal[camelParamName];
      if (existingParam != null) {
        throw AnalyticsParseException(
          'Parameter identifier "${param.codeName}" in $domainName.$eventName '
          'conflicts with "$existingParam" after camelCase normalization.',
          filePath: filePath,
          span: keyNode.span,
        );
      }
      camelNameToOriginal[camelParamName] = param.codeName;

      parameters.add(param);
    }

    return List.unmodifiable(parameters);
  }

  /// Parses a single parameter from a YAML node.
  static AnalyticsParameter parseParameter(
    String rawName,
    YamlNode valueNode, {
    required String domainName,
    required String eventName,
    required String filePath,
    required NamingStrategy naming,
    Map<String, AnalyticsParameter> sharedParameters = const {},
    bool enforceCentrallyDefinedParameters = false,
    bool preventEventParameterDuplicates = false,
  }) {
    final sharedParam = sharedParameters[rawName];

    if (enforceCentrallyDefinedParameters && sharedParam == null) {
      throw AnalyticsParseException(
        'Parameter "$rawName" is not defined in the shared parameters file. '
        'All parameters must be centrally defined when '
        'enforce_centrally_defined_parameters is true.',
        filePath: filePath,
        span: valueNode.span,
      );
    }

    final paramValue = valueNode;

    // Case 1: Reference to shared parameter (value is null)
    if (paramValue is YamlScalar && paramValue.value == null) {
      if (sharedParam != null) {
        return sharedParam;
      }
      // If not shared, fall through to error or dynamic (likely error in strict mode)
    }

    // Case 2: Redefinition of shared parameter
    if (sharedParam != null && preventEventParameterDuplicates) {
      throw AnalyticsParseException(
        'Parameter "$rawName" is already defined in the shared parameters file. '
        'Remove the definitions from the event to use the shared version, '
        'or disable prevent_event_parameter_duplicates.',
        filePath: filePath,
        span: valueNode.span,
      );
    }

    String? identifierOverride;
    String? wireNameOverride;

    if (paramValue is YamlMap) {
      identifierOverride = paramValue['identifier'] as String?;
      wireNameOverride = paramValue['param_name'] as String?;
    }

    final codeIdentifier = identifierOverride ?? rawName;
    final analyticsName = wireNameOverride ?? rawName;

    if (codeIdentifier.isEmpty) {
      throw AnalyticsParseException(
        'Parameter "$rawName" in $domainName.$eventName must declare a '
        'non-empty identifier.',
        filePath: filePath,
        span: valueNode.span,
      );
    }

    if (!naming.isValidParameterIdentifier(codeIdentifier)) {
      throw AnalyticsParseException(
        'Parameter identifier "$codeIdentifier" in $domainName.$eventName '
        'violates the configured naming strategy. Update '
        'analytics_gen.naming.enforce_snake_case_parameters or define a '
        'different `identifier`.',
        filePath: filePath,
        span: valueNode.span,
      );
    }

    String? dartType;
    String paramType;
    String? description;
    List<Object>? allowedValues;
    SourceSpan? allowedValuesSpan;
    String? dartImport;
    String? regex;
    int? minLength;
    int? maxLength;
    num? min;
    num? max;
    Map<String, Object?> meta = const {};
    List<String>? operations;
    String? addedIn;
    String? deprecatedIn;

    if (paramValue is YamlMap) {
      // Complex parameter with 'type' and/or 'description'
      description = paramValue['description'] as String?;
      addedIn = paramValue['added_in'] as String?;
      deprecatedIn = paramValue['deprecated_in'] as String?;
      dartType = paramValue['dart_type'] as String?;

      final metaNode = paramValue.nodes['meta'];
      if (metaNode != null) {
        if (metaNode is! YamlMap) {
          throw AnalyticsParseException(
            'The "meta" field must be a map.',
            filePath: filePath,
            span: metaNode.span,
          );
        }
        meta = const JsonValueNormalizer().normalizeJsonMap(
          metaNode,
          filePath: filePath,
          context: 'meta for parameter "$domainName.$eventName.$rawName"',
          span: metaNode.span,
        );
      }
      dartImport = paramValue['import'] as String?; // Parse import
      // Validation rules
      regex = paramValue['regex'] as String?;
      if (regex != null && regex.contains("'''")) {
        throw AnalyticsParseException(
          'Regex pattern for parameter "$rawName" cannot contain triple quotes '
          "('''). This prevents generation errors in Dart raw strings.",
          filePath: filePath,
          span: paramValue.nodes['regex']?.span ?? valueNode.span,
        );
      }
      minLength = paramValue['min_length'] as int?;
      maxLength = paramValue['max_length'] as int?;
      min = paramValue['min'] as num?;
      max = paramValue['max'] as num?;

      final rawOperations = paramValue.nodes['operations'];
      if (rawOperations != null) {
        if (rawOperations is! YamlList) {
          throw AnalyticsParseException(
            'operations for parameter "$rawName" must be a list.',
            filePath: filePath,
            span: rawOperations.span,
          );
        }
        operations = List<String>.from(
          rawOperations.value.map((e) => e.toString()),
        );
      }

      // Check if 'type' key exists explicitly
      if (paramValue.containsKey('type')) {
        paramType = paramValue['type'].toString();
      } else {
        // Fallback: Find type key (anything except keywords)
        final typeKey = paramValue.keys
            .where(
              (k) =>
                  k.toString() != 'description' &&
                  k.toString() != 'allowed_values' &&
                  k.toString() != 'identifier' &&
                  k.toString() != 'param_name' &&
                  k.toString() != 'dart_type' &&
                  k.toString() != 'meta' &&
                  k.toString() != 'regex' &&
                  k.toString() != 'min_length' &&
                  k.toString() != 'max_length' &&
                  k.toString() != 'min' &&
                  k.toString() != 'max' &&
                  k.toString() != 'operations' &&
                  k.toString() != 'added_in' &&
                  k.toString() != 'deprecated_in' &&
                  k.toString() != 'import',
            )
            .firstOrNull;
        paramType = typeKey?.toString() ?? 'dynamic';
      }

      final rawAllowed = paramValue.nodes['allowed_values'];
      if (rawAllowed != null) {
        if (rawAllowed is! YamlList) {
          throw AnalyticsParseException(
            'allowed_values for parameter "$rawName" must be a list.',
            filePath: filePath,
            span: rawAllowed.span,
          );
        }
        if (rawAllowed.value.isEmpty) {
          throw AnalyticsParseException(
            'allowed_values for parameter "$rawName" must be a non-empty list.',
            filePath: filePath,
            span: rawAllowed.span,
          );
        }
        allowedValuesSpan = rawAllowed.span;
        allowedValues = List<Object>.from(rawAllowed.value);
      }
    } else {
      // Simple parameter (just type)
      paramType = paramValue.toString();
    }

    // Check if nullable
    var isNullable = paramType.endsWith('?');
    if (isNullable) {
      paramType = paramType.substring(0, paramType.length - 1);
    }

    if (dartType != null && dartType.endsWith('?')) {
      isNullable = true;
      dartType = dartType.substring(0, dartType.length - 1);
    }

    if (allowedValues != null) {
      if (dartType != null) {
        throw AnalyticsParseException(
          'Parameter "$rawName" in $domainName.$eventName cannot define both '
          '"dart_type" and "allowed_values". Choose one.',
          filePath: filePath,
          span: allowedValuesSpan ?? valueNode.span,
        );
      }

      final normalizedType = paramType.trim().toLowerCase();

      switch (normalizedType) {
        case 'string':
          if (allowedValues.any((v) => v is! String)) {
            throw AnalyticsParseException(
              'allowed_values for parameter "$rawName" must be a list of strings '
              'because its type is "string".',
              filePath: filePath,
              span: allowedValuesSpan ?? valueNode.span,
            );
          }
          break;
        case 'bool':
          if (allowedValues.any((v) => v is! bool)) {
            throw AnalyticsParseException(
              'allowed_values for parameter "$rawName" must be a list of booleans '
              'because its type is "bool".',
              filePath: filePath,
              span: allowedValuesSpan ?? valueNode.span,
            );
          }
          break;
        case 'int':
          if (allowedValues.any((v) => v is! int)) {
            throw AnalyticsParseException(
              'allowed_values for parameter "$rawName" must be a list of integers '
              'because its type is "int".',
              filePath: filePath,
              span: allowedValuesSpan ?? valueNode.span,
            );
          }
          break;
        case 'double' || 'float':
          if (allowedValues.any((v) => v is! num)) {
            throw AnalyticsParseException(
              'allowed_values for parameter "$rawName" must be a list of numbers '
              'because its type is "$normalizedType".',
              filePath: filePath,
              span: allowedValuesSpan ?? valueNode.span,
            );
          }
          // Normalize numeric literals to doubles so the generated const Set<double>
          // remains type-correct (e.g. `1` -> `1.0`).
          allowedValues = allowedValues
              .map<Object>((v) => (v as num).toDouble())
              .toList(growable: false);
          break;
        case 'num' || 'number':
          if (allowedValues.any((v) => v is! num)) {
            throw AnalyticsParseException(
              'allowed_values for parameter "$rawName" must be a list of numbers '
              'because its type is "$normalizedType".',
              filePath: filePath,
              span: allowedValuesSpan ?? valueNode.span,
            );
          }
          break;
        default:
          throw AnalyticsParseException(
            'allowed_values is only supported for scalar parameter types '
            '(string, bool, int, double, num). '
            'Parameter "$rawName" has unsupported type "$paramType".',
            filePath: filePath,
            span: allowedValuesSpan ?? valueNode.span,
          );
      }
    }

    return AnalyticsParameter(
      name: analyticsName,
      codeName: codeIdentifier,
      type: paramType,
      dartType: dartType,
      dartImport: dartImport,
      isNullable: isNullable,
      description: description,
      allowedValues: allowedValues == null
          ? null
          : List<Object>.unmodifiable(allowedValues),
      regex: regex,
      minLength: minLength,
      maxLength: maxLength,
      min: min,
      max: max,
      meta: meta,
      operations:
          operations == null ? null : List<String>.unmodifiable(operations),
      addedIn: addedIn,
      deprecatedIn: deprecatedIn,
      sourceName: rawName,
    );
  }
}
