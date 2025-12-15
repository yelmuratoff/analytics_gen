import '../../config/analytics_config.dart';
import '../../models/analytics_domain.dart';
import '../../models/analytics_event.dart';
import '../../util/event_naming.dart';
import '../../util/string_utils.dart';
import 'cross_domain_validation_result.dart';

/// Validates and resolves cross-domain event calls.
class CrossDomainValidator {
  /// Creates a new instance of `CrossDomainValidator`.
  const CrossDomainValidator(this.config);

  /// The configuration used for validation.
  final AnalyticsConfig config;

  /// Validates if a dual-write target can be resolved to a strongly-typed method call.
  CrossDomainValidationResult validate(
    String target,
    String currentDomain,
    AnalyticsEvent currentEvent,
    Map<String, AnalyticsDomain> allDomains, {
    String parametersArgName = 'parameters',
  }) {
    final parts = target.split('.');

    // Fallback resolution logic
    String resolveFallbackName() {
      if (parts.length != 2) return target;
      final domain = allDomains[parts[0]];
      if (domain == null) return target;
      final eventIndex = domain.events.indexWhere((e) => e.name == parts[1]);
      if (eventIndex == -1) return target;
      return EventNaming.resolveEventName(
          parts[0], domain.events[eventIndex], config.naming);
    }

    final fallbackName = resolveFallbackName();

    if (parts.length != 2) {
      return CrossDomainValidationResult.invalid(
          fallbackEventName: fallbackName);
    }

    final targetDomainName = parts[0];
    final targetEventName = parts[1];

    // Can only call methods within the same domain (mixin constraint)
    if (targetDomainName != currentDomain) {
      return CrossDomainValidationResult.invalid(
          fallbackEventName: fallbackName);
    }

    final domain = allDomains[targetDomainName];
    if (domain == null) {
      return CrossDomainValidationResult.invalid(
          fallbackEventName: fallbackName);
    }

    final targetEventIndex =
        domain.events.indexWhere((e) => e.name == targetEventName);

    if (targetEventIndex == -1) {
      return CrossDomainValidationResult.invalid(
          fallbackEventName: fallbackName);
    }

    final targetEvent = domain.events[targetEventIndex];

    final methodName = EventNaming.buildLoggerMethodName(
      targetDomainName,
      targetEvent.name,
    );

    final args = <String, String>{};

    for (final targetParam in targetEvent.parameters) {
      // Find matching parameter in current event
      final sourceParamIndex = currentEvent.parameters.indexWhere((p) {
        // Match by source name (YAML key) if available
        if (p.sourceName != null && targetParam.sourceName != null) {
          return p.sourceName == targetParam.sourceName;
        }
        // Fallback to code name
        return p.codeName == targetParam.codeName;
      });

      if (sourceParamIndex == -1) {
        if (!targetParam.isNullable) {
          // Required parameter missing in source -> cannot call method safely
          return CrossDomainValidationResult.invalid(
              fallbackEventName: fallbackName);
        }
        continue;
      }

      final sourceParam = currentEvent.parameters[sourceParamIndex];
      final sourceVarName = StringUtils.toCamelCase(sourceParam.codeName);

      final sourceIsEnum = sourceParam.type == 'string' &&
          sourceParam.allowedValues != null &&
          sourceParam.allowedValues!.isNotEmpty;
      final targetIsEnum = targetParam.type == 'string' &&
          targetParam.allowedValues != null &&
          targetParam.allowedValues!.isNotEmpty;

      // Handle dart_type matching
      if (sourceParam.dartType != null || targetParam.dartType != null) {
        if (sourceParam.dartType == targetParam.dartType) {
          args[targetParam.name] = sourceVarName;
        } else {
          // Mismatch in dart_type, cannot guarantee compatibility
          return CrossDomainValidationResult.invalid(
              fallbackEventName: fallbackName);
        }
      } else if (targetParam.type == sourceParam.type) {
        if (sourceIsEnum && !targetIsEnum) {
          // Enum -> String
          args[targetParam.name] = '$sourceVarName.value';
        } else if (sourceIsEnum == targetIsEnum) {
          // Both Enum or Both String (or other types)
          args[targetParam.name] = sourceVarName;
        } else {
          // String -> Enum (Cannot handle easily)
          return CrossDomainValidationResult.invalid(
              fallbackEventName: fallbackName);
        }
      } else {
        // Type mismatch -> cannot call method safely
        return CrossDomainValidationResult.invalid(
            fallbackEventName: fallbackName);
      }
    }

    // Add the spread parameters map
    args['parameters'] = parametersArgName;

    return CrossDomainValidationResult.valid(
      methodName: methodName,
      arguments: args,
    );
  }
}
