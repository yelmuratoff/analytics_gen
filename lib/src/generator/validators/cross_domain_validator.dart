import '../../config/analytics_config.dart';
import '../../models/analytics_domain.dart';
import '../../models/analytics_event.dart';
import '../../models/analytics_parameter.dart';
import '../../util/event_naming.dart';
import '../../util/string_utils.dart';
import '../model_codegen.dart';
import '../renderers/enum_renderer.dart';
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

      final argument = _argumentFor(
        currentEvent.parameters[sourceParamIndex],
        targetParam,
        targetDomainName: targetDomainName,
        targetEvent: targetEvent,
      );
      if (argument == null) {
        return CrossDomainValidationResult.invalid(
            fallbackEventName: fallbackName);
      }
      args[targetParam.codeName] = argument;
    }

    // Add the spread parameters map
    args['parameters'] = parametersArgName;

    return CrossDomainValidationResult.valid(
      methodName: methodName,
      arguments: args,
    );
  }

  /// Returns the Dart expression that passes [source] to the generated
  /// method's [target] parameter, or null when no expression type-checks.
  String? _argumentFor(
    AnalyticsParameter source,
    AnalyticsParameter target, {
    required String targetDomainName,
    required AnalyticsEvent targetEvent,
  }) {
    if (source.isNullable && !target.isNullable) return null;
    final variable = StringUtils.toCamelCase(source.codeName);

    if (source.dartType != null || target.dartType != null) {
      return source.dartType == target.dartType ? variable : null;
    }
    if (source.type != target.type) return null;

    return switch ((source.usesGeneratedEnum, target.usesGeneratedEnum)) {
      (false, false) => variable,
      (true, false) =>
        source.isNullable ? '$variable?.value' : '$variable.value',
      (true, true) => _convertEnum(
          variable,
          source,
          target,
          targetDomainName: targetDomainName,
          targetEvent: targetEvent,
        ),
      (false, true) => null,
    };
  }

  /// Converts between the generated enums of two events by constant name,
  /// which is defined only when every source value exists in the target.
  String? _convertEnum(
    String variable,
    AnalyticsParameter source,
    AnalyticsParameter target, {
    required String targetDomainName,
    required AnalyticsEvent targetEvent,
  }) {
    final targetValues = target.allowedValues!.toSet();
    if (!source.allowedValues!.every(targetValues.contains)) return null;

    final targetEnum = const EnumRenderer()
        .buildEnumName(targetDomainName, targetEvent, target);
    final conversion = '$targetEnum.values.byName($variable.name)';
    return source.isNullable
        ? '$variable == null ? null : $conversion'
        : conversion;
  }
}
