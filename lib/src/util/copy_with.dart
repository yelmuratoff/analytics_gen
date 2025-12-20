/// Sentinel value for copyWith methods to distinguish between
/// "not provided" and "explicitly set to null".
///
/// This solves the common Dart problem where nullable fields cannot be
/// explicitly cleared via copyWith because `null` is indistinguishable
/// from "parameter not provided".
///
/// Usage:
/// ```dart
/// T copyWith<T>({
///   Object? field = copyWithNull,
/// }) {
///   return T(
///     field: field == copyWithNull ? this.field : field as String?,
///   );
/// }
///
/// // Keep current value
/// event.copyWith();
///
/// // Set to new value
/// event.copyWith(identifier: 'new-id');
///
/// // Explicitly clear to null
/// event.copyWith(identifier: null);
/// ```
const Object copyWithNull = _CopyWithNull();

class _CopyWithNull {
  const _CopyWithNull();

  @override
  String toString() => 'copyWithNull';
}
