/// Result of a cross-domain event link validation.
class CrossDomainValidationResult {
  /// Creates a successful validation result.
  const CrossDomainValidationResult.valid({
    required this.methodName,
    required this.arguments,
  })  : isValid = true,
        fallbackEventName = null;

  /// Creates a failed validation result.
  const CrossDomainValidationResult.invalid({
    required this.fallbackEventName,
  })  : isValid = false,
        methodName = null,
        arguments = null;

  /// Whether the link is valid and a strongly-typed method call can be generated.
  final bool isValid;

  /// The name of the method to call (if valid).
  final String? methodName;

  /// The arguments to pass to the method (key: parameter name, value: Dart expression).
  final Map<String, String>? arguments;

  /// The resolved event name to use for the fallback generic log (if invalid).
  final String? fallbackEventName;
}
