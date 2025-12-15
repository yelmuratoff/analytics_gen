import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import '../util/copy_with.dart';

/// Represents a single analytics event parameter.
@immutable
final class AnalyticsParameter {
  /// Parses a parameter from a YAML node.

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
      dartType: map['dart_type'] as String?,
      dartImport: map['import'] as String?,
      isNullable: map['is_nullable'] as bool? ?? false,
      description: map['description'] as String?,
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
    this.dartType,
    this.dartImport,
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

  /// The explicitly configured Dart enum type (or other type) for this parameter.
  ///
  /// If provided, the generator will use this type in the method signature
  /// instead of the inferred type, and will serialize it using `.name`.
  final String? dartType;

  /// The custom import path for the explicit Dart type.
  final String? dartImport;

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

  @override
  String toString() => '$name: ${dartType ?? type}${isNullable ? '?' : ''}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final collectionEquals = const DeepCollectionEquality().equals;

    return other is AnalyticsParameter &&
        other.name == name &&
        other.sourceName == sourceName &&
        other.codeName == codeName &&
        other.type == type &&
        other.dartType == dartType &&
        other.dartImport == dartImport &&
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
      dartType,
      dartImport,
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
  ///
  /// Nullable fields use [copyWithNull] sentinel to distinguish between
  /// "not provided" and "explicitly set to null".
  AnalyticsParameter copyWith({
    String? name,
    Object? sourceName = copyWithNull,
    String? codeName,
    String? type,
    Object? dartType = copyWithNull,
    Object? dartImport = copyWithNull,
    Object? description = copyWithNull,
    bool? isNullable,
    Object? allowedValues = copyWithNull,
    Object? regex = copyWithNull,
    Object? minLength = copyWithNull,
    Object? maxLength = copyWithNull,
    Object? min = copyWithNull,
    Object? max = copyWithNull,
    Map<String, dynamic>? meta,
    Object? operations = copyWithNull,
    Object? addedIn = copyWithNull,
    Object? deprecatedIn = copyWithNull,
  }) {
    return AnalyticsParameter(
      name: name ?? this.name,
      sourceName:
          sourceName == copyWithNull ? this.sourceName : sourceName as String?,
      codeName: codeName ?? this.codeName,
      type: type ?? this.type,
      dartType: dartType == copyWithNull ? this.dartType : dartType as String?,
      dartImport:
          dartImport == copyWithNull ? this.dartImport : dartImport as String?,
      isNullable: isNullable ?? this.isNullable,
      description: description == copyWithNull
          ? this.description
          : description as String?,
      allowedValues: allowedValues == copyWithNull
          ? this.allowedValues
          : allowedValues as List<dynamic>?,
      regex: regex == copyWithNull ? this.regex : regex as String?,
      minLength: minLength == copyWithNull ? this.minLength : minLength as int?,
      maxLength: maxLength == copyWithNull ? this.maxLength : maxLength as int?,
      min: min == copyWithNull ? this.min : min as num?,
      max: max == copyWithNull ? this.max : max as num?,
      meta: meta ?? this.meta,
      operations: operations == copyWithNull
          ? this.operations
          : operations as List<String>?,
      addedIn: addedIn == copyWithNull ? this.addedIn : addedIn as String?,
      deprecatedIn: deprecatedIn == copyWithNull
          ? this.deprecatedIn
          : deprecatedIn as String?,
    );
  }

  /// Converts this analytics parameter to a map.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'source_name': sourceName,
      'code_name': codeName,
      'type': type,
      'dart_type': dartType,
      'import': dartImport,
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
