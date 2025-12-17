import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import '../util/copy_with.dart';

/// Represents a single analytics event parameter.
@immutable
final class AnalyticsParameter {
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
    this.sanitize,
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

  /// Custom metadata for this parameter (e.g. ownership).
  final Map<String, dynamic> meta;

  /// List of operations supported by this parameter (e.g. set, increment).
  /// Only used for context properties.
  final List<String>? operations;

  /// Version when this parameter was added.
  final String? addedIn;

  /// Version when this parameter was deprecated.
  final String? deprecatedIn;

  /// The sanitization rule (e.g. 'html', 'sql').
  final String? sanitize;

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
        other.deprecatedIn == deprecatedIn &&
        other.sanitize == sanitize;
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
      sanitize,
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
    Object? sanitize = copyWithNull,
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
      sanitize: sanitize == copyWithNull ? this.sanitize : sanitize as String?,
    );
  }
}
