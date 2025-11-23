import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import '../config/naming_strategy.dart';
import '../core/exceptions.dart';
import '../util/string_utils.dart';

/// Represents a single analytics event parameter.
@immutable
final class AnalyticsParameter {
  /// Parses a parameter from a YAML node.
  factory AnalyticsParameter.fromYaml(
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
        'Remove the definition from the event to use the shared version, '
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
    String? addedIn;
    String? deprecatedIn;

    if (paramValue is YamlMap) {
      // Complex parameter with 'type' and/or 'description'
      description = paramValue['description'] as String?;
      addedIn = paramValue['added_in'] as String?;
      deprecatedIn = paramValue['deprecated_in'] as String?;

      final metaNode = paramValue.nodes['meta'];
      if (metaNode != null) {
        if (metaNode is! YamlMap) {
          throw AnalyticsParseException(
            'The "meta" field must be a map.',
            filePath: filePath,
            span: metaNode.span,
          );
        }
        meta = metaNode.map((key, value) => MapEntry(key.toString(), value));
      }

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
                  k.toString() != 'operations' &&
                  k.toString() != 'added_in' &&
                  k.toString() != 'deprecated_in',
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

    return AnalyticsParameter(
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
      addedIn: addedIn,
      deprecatedIn: deprecatedIn,
      sourceName: rawName,
    );
  }

  /// Creates a new analytics parameter from a map.
  factory AnalyticsParameter.fromMap(Map<String, dynamic> map) {
    T cast<T>(String k) => map[k] is T
        ? map[k] as T
        : throw ArgumentError.value(map[k], k, '$T ← ${map[k].runtimeType}');
    return AnalyticsParameter(
      name: cast<String?>('name') ?? '',
      sourceName: cast<String?>('source_name'),
      codeName: cast<String?>('code_name') ?? '',
      type: cast<String?>('type') ?? '',
      isNullable: cast<bool?>('is_nullable') ?? false,
      description: cast<String?>('description'),
      allowedValues: map['allowed_values'] != null
          ? List<dynamic>.from(cast<Iterable>('allowed_values'))
          : null,
      regex: cast<String?>('regex'),
      minLength: cast<num?>('min_length')?.toInt(),
      maxLength: cast<num?>('max_length')?.toInt(),
      min: cast<num?>('min'),
      max: cast<num?>('max'),
      meta: Map<String, dynamic>.from(cast<Map?>('meta') ?? const {}),
      operations: map['operations'] != null
          ? List<String>.from(cast<Iterable>('operations'))
          : null,
      addedIn: cast<String?>('added_in'),
      deprecatedIn: cast<String?>('deprecated_in'),
    );
  }

  /// Creates a new analytics parameter from a JSON string.
  factory AnalyticsParameter.fromJson(String source) =>
      AnalyticsParameter.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Creates a new analytics parameter.
  const AnalyticsParameter({
    String? codeName,
    required this.name,
    this.sourceName,
    required this.type,
    required this.isNullable,
    this.description,
    this.allowedValues,
    this.regex,
    this.minLength,
    this.maxLength,
    this.min,
    this.max,
    this.meta = const {},
    this.operations,
    this.addedIn,
    this.deprecatedIn,
  }) : codeName = codeName ?? name;

  /// Analytics key that gets sent to providers.
  final String name;

  /// The original key in the YAML file (if different from name).
  final String? sourceName;

  /// Identifier used when generating Dart API (defaults to [name]).
  final String codeName;

  /// The Dart type of the parameter.
  final String type;

  /// Whether the parameter is nullable.
  final bool isNullable;

  /// Optional description of the parameter.
  final String? description;

  /// Optional list of allowed values.
  final List<dynamic>? allowedValues;

  /// Regex pattern for validation.
  final String? regex;

  /// Minimum length for string parameters.
  final int? minLength;

  /// Maximum length for string parameters.
  final int? maxLength;

  /// Minimum value for numeric parameters.
  final num? min;

  /// Maximum value for numeric parameters.
  final num? max;

  /// Custom metadata for this parameter (e.g. PII flags, ownership).
  final Map<String, dynamic> meta;

  /// List of operations supported by this parameter (e.g. set, increment).
  /// Only used for context properties.
  final List<String>? operations;

  /// Version when this parameter was added.
  final String? addedIn;

  /// Version when this parameter was deprecated.
  final String? deprecatedIn;

  /// Parses a list of parameters from a YAML map.
  static List<AnalyticsParameter> fromYamlMap(
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

      final param = AnalyticsParameter.fromYaml(
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

    return parameters;
  }

  @override
  String toString() => '$name: $type${isNullable ? '?' : ''}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final collectionEquals = const DeepCollectionEquality().equals;

    return other is AnalyticsParameter &&
        other.name == name &&
        other.sourceName == sourceName &&
        other.codeName == codeName &&
        other.type == type &&
        other.isNullable == isNullable &&
        other.description == description &&
        collectionEquals(other.allowedValues, allowedValues) &&
        other.regex == regex &&
        other.minLength == minLength &&
        other.maxLength == maxLength &&
        other.min == min &&
        other.max == max &&
        collectionEquals(other.meta, meta) &&
        collectionEquals(other.operations, operations) &&
        other.addedIn == addedIn &&
        other.deprecatedIn == deprecatedIn;
  }

  @override
  int get hashCode {
    final deepHash = const DeepCollectionEquality().hash;

    return Object.hashAll([
      name,
      sourceName,
      codeName,
      type,
      isNullable,
      description,
      deepHash(allowedValues),
      regex,
      minLength,
      maxLength,
      min,
      max,
      deepHash(meta),
      deepHash(operations),
      addedIn,
      deprecatedIn,
    ]);
  }

  /// Creates a copy of this analytics parameter with the specified properties.
  AnalyticsParameter copyWith({
    String? name,
    String? sourceName,
    String? codeName,
    String? type,
    bool? isNullable,
    String? description,
    List<dynamic>? allowedValues,
    String? regex,
    int? minLength,
    int? maxLength,
    num? min,
    num? max,
    Map<String, dynamic>? meta,
    List<String>? operations,
    String? addedIn,
    String? deprecatedIn,
  }) {
    return AnalyticsParameter(
      name: name ?? this.name,
      sourceName: sourceName ?? this.sourceName,
      codeName: codeName ?? this.codeName,
      type: type ?? this.type,
      isNullable: isNullable ?? this.isNullable,
      description: description ?? this.description,
      allowedValues: allowedValues ?? this.allowedValues,
      regex: regex ?? this.regex,
      minLength: minLength ?? this.minLength,
      maxLength: maxLength ?? this.maxLength,
      min: min ?? this.min,
      max: max ?? this.max,
      meta: meta ?? this.meta,
      operations: operations ?? this.operations,
      addedIn: addedIn ?? this.addedIn,
      deprecatedIn: deprecatedIn ?? this.deprecatedIn,
    );
  }

  /// Converts this analytics parameter to a map.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'source_name': sourceName,
      'code_name': codeName,
      'type': type,
      'is_nullable': isNullable,
      'description': description,
      'allowed_values': allowedValues,
      'regex': regex,
      'min_length': minLength,
      'max_length': maxLength,
      'min': min,
      'max': max,
      'meta': meta,
      'operations': operations,
      'added_in': addedIn,
      'deprecated_in': deprecatedIn,
    };
  }

  /// Converts this analytics parameter to a JSON string.
  String toJson() => json.encode(toMap());
}
