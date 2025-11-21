import 'package:yaml/yaml.dart';

import '../config/naming_strategy.dart';
import '../core/exceptions.dart';
import '../models/analytics_event.dart';
import '../util/string_utils.dart';

/// Helper class responsible for parsing analytics parameters from YAML.
class ParameterParser {
  /// Creates a new parameter parser.
  const ParameterParser(this.naming);

  /// The naming strategy to use.
  final NamingStrategy naming;

  /// Parses a list of parameters from a YAML map.
  List<AnalyticsParameter> parseParameters(
    YamlMap parametersYaml, {
    required String domainName,
    required String eventName,
    required String filePath,
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

      final sharedParam = sharedParameters[rawName];

      if (enforceCentrallyDefinedParameters && sharedParam == null) {
        throw AnalyticsParseException(
          'Parameter "$rawName" is not defined in the shared parameters file. '
          'All parameters must be centrally defined when '
          'enforce_centrally_defined_parameters is true.',
          filePath: filePath,
          span: keyNode.span,
        );
      }

      final valueNode = entry.value;
      final paramValue = valueNode;

      // Case 1: Reference to shared parameter (value is null)
      if (paramValue is YamlScalar && paramValue.value == null) {
        if (sharedParam != null) {
          parameters.add(sharedParam);
          continue;
        }
        // If not shared, fall through to error or dynamic (likely error in strict mode)
      }

      // Case 2: Redefinition of shared parameter
      if (sharedParam != null && preventEventParameterDuplicates) {
        throw AnalyticsParseException(
          'Parameter "$rawName" is already defined in the shared parameters file. '
          'Remove the definition from the event to use the shared version, '
          'or disable prevent_event_parameter_duplicates.',
          filePath: filePath,
          span: keyNode.span,
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
          span: keyNode.span,
        );
      }

      if (!naming.isValidParameterIdentifier(codeIdentifier)) {
        throw AnalyticsParseException(
          'Parameter identifier "$codeIdentifier" in $domainName.$eventName '
          'violates the configured naming strategy. Update '
          'analytics_gen.naming.enforce_snake_case_parameters or define a '
          'different `identifier`.',
          filePath: filePath,
          span: keyNode.span,
        );
      }

      if (!seenAnalyticsNames.add(analyticsName)) {
        throw AnalyticsParseException(
          'Duplicate analytics parameter "$analyticsName" found in '
          '$domainName.$eventName.',
          filePath: filePath,
          span: keyNode.span,
        );
      }

      final camelParamName = StringUtils.toCamelCase(codeIdentifier);
      final existingParam = camelNameToOriginal[camelParamName];
      if (existingParam != null) {
        throw AnalyticsParseException(
          'Parameter identifier "$codeIdentifier" in $domainName.$eventName '
          'conflicts with "$existingParam" after camelCase normalization.',
          filePath: filePath,
          span: keyNode.span,
        );
      }
      camelNameToOriginal[camelParamName] = codeIdentifier;

      String paramType;
      String? description;
      List<Object>? allowedValues;
      String? regex;
      int? minLength;
      int? maxLength;
      num? min;
      num? max;
      Map<String, Object?> meta = const {};
      List<String>? operations;

      if (paramValue is YamlMap) {
        // Complex parameter with 'type' and/or 'description'
        description = paramValue['description'] as String?;

        final metaNode = paramValue.nodes['meta'];
        meta = _parseMeta(metaNode, filePath);

        // Validation rules
        regex = paramValue['regex'] as String?;
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
          // Fallback: Find type key (anything except 'description')
          final typeKey = paramValue.keys
              .where(
                (k) =>
                    k.toString() != 'description' &&
                    k.toString() != 'allowed_values' &&
                    k.toString() != 'identifier' &&
                    k.toString() != 'param_name' &&
                    k.toString() != 'meta' &&
                    k.toString() != 'regex' &&
                    k.toString() != 'min_length' &&
                    k.toString() != 'max_length' &&
                    k.toString() != 'min' &&
                    k.toString() != 'max' &&
                    k.toString() != 'operations',
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
          allowedValues = List<Object>.from(rawAllowed.value);
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
          operations: operations,
        ),
      );
    }

    return parameters;
  }

  Map<String, Object?> _parseMeta(YamlNode? metaNode, String filePath) {
    if (metaNode == null) return const {};
    if (metaNode is! YamlMap) {
      throw AnalyticsParseException(
        'The "meta" field must be a map.',
        filePath: filePath,
        span: metaNode.span,
      );
    }
    // Convert YamlMap to Map<String, Object?>
    return metaNode.map((key, value) => MapEntry(key.toString(), value));
  }
}
