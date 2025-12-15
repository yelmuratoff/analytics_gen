import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';

import '../../../util/event_naming.dart';
import '../../../util/string_utils.dart';
import '../../../util/type_mapper.dart';
import 'validation_renderer.dart';

/// Renders the body of event logger methods.
class EventBodyRenderer {
  /// Creates a new event body renderer.
  const EventBodyRenderer(this.config);

  /// The analytics configuration.
  final AnalyticsConfig config;

  static final _placeholderRegex = RegExp(r'\{([^}]+)\}');

  /// Renders the method body.
  String renderBody(
    String domainName,
    AnalyticsEvent event,
    Map<String, AnalyticsDomain> allDomains, {
    int indent = 0,
  }) {
    final buffer = StringBuffer();
    final indentStr = '  ' * indent;

    // 1. Validation Logic
    buffer.write(_renderValidations(domainName, event, indent: indent));

    // 2. Prepare event name
    final eventName =
        EventNaming.resolveEventName(domainName, event, config.naming);
    final interpolatedEventName = _replacePlaceholdersWithInterpolation(
      eventName,
      event.parameters,
    );

    // 3. Prepare parameters map
    final includeDescription =
        config.includeEventDescription && event.description.isNotEmpty;

    final hasParametersParam = event.parameters
        .any((p) => StringUtils.toCamelCase(p.codeName) == 'parameters');
    final parametersArgName =
        hasParametersParam ? 'analyticsParameters' : 'parameters';

    if (event.parameters.isNotEmpty || includeDescription) {
      final isConst = event.parameters.isEmpty;
      buffer.writeln(
          '$indentStr    final eventParameters = $parametersArgName ?? ${isConst ? 'const ' : ''}<String, Object?>{');

      if (includeDescription) {
        buffer.writeln(
          "$indentStr      'description': '${StringUtils.escapeSingleQuoted(event.description)}',",
        );
      }
      for (final param in event.parameters) {
        final camelParam = StringUtils.toCamelCase(param.codeName);
        final isEnum = param.type == 'string' &&
            param.allowedValues != null &&
            param.allowedValues!.isNotEmpty;

        String valueAccess;
        if (param.dartType != null) {
          // Serialize external Dart types using .name (assumed Enum)
          valueAccess =
              param.isNullable ? '$camelParam?.name' : '$camelParam.name';
        } else if (isEnum) {
          // Serialize generated Enum wrappers using .value
          valueAccess =
              param.isNullable ? '$camelParam?.value' : '$camelParam.value';
        } else {
          valueAccess = camelParam;
        }

        if (param.isNullable) {
          buffer.writeln(
            '$indentStr      if ($camelParam != null) "${param.name}": $valueAccess,',
          );
        } else {
          buffer.writeln('$indentStr      "${param.name}": $valueAccess,');
        }
      }
      buffer.writeln('$indentStr    };');
      buffer.writeln();

      buffer.writeln('$indentStr    logger.logEvent(');
      buffer.writeln('$indentStr      name: "$interpolatedEventName",');
      buffer.writeln('$indentStr      parameters: eventParameters,');
      buffer.writeln('$indentStr    );');

      // 4. Dual write logic
      if (event.dualWriteTo != null) {
        buffer.write(_renderDualWrite(
          domainName,
          event,
          allDomains,
          parametersArgName,
          eventParametersVar: 'eventParameters',
          indent: indent,
        ));
      }
    } else {
      buffer.writeln(
          '$indentStr    final eventParameters = parameters ?? const <String, Object?>{};');
      buffer.writeln('$indentStr    logger.logEvent(');
      buffer.writeln('$indentStr      name: "$interpolatedEventName",');
      buffer.writeln('$indentStr      parameters: eventParameters,');
      buffer.writeln('$indentStr    );');

      if (event.dualWriteTo != null) {
        buffer.write(_renderDualWrite(
          domainName,
          event,
          allDomains,
          parametersArgName,
          eventParametersVar: 'eventParameters',
          indent: indent,
        ));
      }
    }

    return buffer.toString();
  }

  String _renderValidations(
    String domainName,
    AnalyticsEvent event, {
    int indent = 0,
  }) {
    final buffer = StringBuffer();
    final validator = const ValidationRenderer(); // Use stateless validator

    for (final param in event.parameters) {
      // Skip validation for external Dart types as valid values are enforced by type
      if (param.dartType != null) continue;

      final isEnum = param.type == 'string' &&
          param.allowedValues != null &&
          param.allowedValues!.isNotEmpty;

      if (!isEnum) {
        final allowedValues = param.allowedValues;
        if (allowedValues != null && allowedValues.isNotEmpty) {
          final camelParam = StringUtils.toCamelCase(param.codeName);
          final constName =
              'allowed${StringUtils.capitalizePascal(camelParam)}Values';
          final encodedValues = validator.encodeAllowedValues(allowedValues);
          final joinedValues = validator.joinAllowedValues(allowedValues);
          final dartType = DartTypeMapper.toDartType(param.type);

          buffer.write(validator.renderAllowedValuesCheck(
            camelParam: camelParam,
            constName: constName,
            encodedValues: encodedValues,
            joinedValues: joinedValues,
            isNullable: param.isNullable,
            type: dartType,
            indent: indent,
          ));
        }
      }

      // Validation rules
      if (param.regex != null ||
          param.minLength != null ||
          param.maxLength != null ||
          param.min != null ||
          param.max != null) {
        final camelParam = StringUtils.toCamelCase(param.codeName);
        buffer.write(validator.renderValidationChecks(
          camelParam: camelParam,
          isNullable: param.isNullable,
          regex: param.regex,
          minLength: param.minLength,
          maxLength: param.maxLength,
          min: param.min,
          max: param.max,
          indent: indent,
        ));
      }
    }
    return buffer.toString();
  }

  String _renderDualWrite(
    String domainName,
    AnalyticsEvent event,
    Map<String, AnalyticsDomain> allDomains,
    String parametersArgName, {
    required String eventParametersVar,
    int indent = 0,
  }) {
    final buffer = StringBuffer();
    final indentStr = '  ' * indent;

    for (final target in event.dualWriteTo!) {
      buffer.writeln();
      buffer.writeln('$indentStr    // Dual-write to: $target');

      final methodCall = _tryGenerateMethodCall(
        target,
        domainName,
        event,
        allDomains,
        parametersArgName: parametersArgName,
      );

      if (methodCall != null) {
        buffer.writeln('$indentStr    $methodCall');
      } else {
        final resolvedName = _resolveTargetEventName(target, allDomains);
        buffer.writeln('$indentStr    logger.logEvent(');
        buffer.writeln('$indentStr      name: "$resolvedName",');
        buffer.writeln('$indentStr      parameters: $eventParametersVar,');
        buffer.writeln('$indentStr    );');
      }
    }
    return buffer.toString();
  }

  String? _tryGenerateMethodCall(
    String target,
    String currentDomain,
    AnalyticsEvent currentEvent,
    Map<String, AnalyticsDomain> allDomains, {
    String parametersArgName = 'parameters',
  }) {
    final parts = target.split('.');
    if (parts.length != 2) return null;

    final targetDomainName = parts[0];
    final targetEventName = parts[1];

    // Can only call methods within the same domain (mixin)
    if (targetDomainName != currentDomain) return null;

    final domain = allDomains[targetDomainName];
    if (domain == null) return null;

    final targetEvent = domain.events
        .cast<AnalyticsEvent?>()
        .firstWhere((e) => e?.name == targetEventName, orElse: () => null);

    if (targetEvent == null) return null;

    final methodName = EventNaming.buildLoggerMethodName(
      targetDomainName,
      targetEvent.name,
    );

    final args = <String>[];
    for (final targetParam in targetEvent.parameters) {
      // Find matching parameter in current event
      final sourceParam =
          currentEvent.parameters.cast<AnalyticsParameter?>().firstWhere((p) {
        if (p == null) return false;
        // Match by source name (YAML key) if available
        if (p.sourceName != null && targetParam.sourceName != null) {
          return p.sourceName == targetParam.sourceName;
        }
        // Fallback to code name
        return p.codeName == targetParam.codeName;
      }, orElse: () => null);

      if (sourceParam == null) {
        if (!targetParam.isNullable) {
          // Required parameter missing in source -> cannot call method safely
          return null;
        }
        continue;
      }

      final targetArgName = StringUtils.toCamelCase(targetParam.codeName);
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
          args.add('$targetArgName: $sourceVarName');
        } else {
          // Mismatch in dart_type, cannot guarantee compatibility
          return null;
        }
      } else if (targetParam.type == sourceParam.type) {
        if (sourceIsEnum && !targetIsEnum) {
          // Enum -> String
          args.add('$targetArgName: $sourceVarName.value');
        } else if (sourceIsEnum == targetIsEnum) {
          // Both Enum or Both String (or other types)
          args.add('$targetArgName: $sourceVarName');
        } else {
          // String -> Enum (Cannot handle easily)
          return null;
        }
      } else {
        // Type mismatch -> cannot call method safely
        return null;
      }
    }

    // Pass the parameters map to preserve extra parameters
    args.add('parameters: $parametersArgName');

    return '$methodName(${args.join(', ')});';
  }

  String _resolveTargetEventName(
    String target,
    Map<String, AnalyticsDomain> allDomains,
  ) {
    final parts = target.split('.');
    if (parts.length != 2) {
      // Fallback if format is not domain.event
      return target;
    }

    final domainName = parts[0];
    final eventName = parts[1];

    final domain = allDomains[domainName];
    if (domain == null) {
      return target;
    }

    final event = domain.events
        .cast<AnalyticsEvent?>()
        .firstWhere((e) => e?.name == eventName, orElse: () => null);

    if (event == null) {
      return target;
    }

    return EventNaming.resolveEventName(domainName, event, config.naming);
  }

  String _replacePlaceholdersWithInterpolation(
    String eventName,
    List<AnalyticsParameter> parameters,
  ) {
    return eventName.replaceAllMapped(_placeholderRegex, (match) {
      final key = match.group(1)!;
      final found = parameters.where((p) => p.name == key).toList();
      if (found.isEmpty) return match.group(0)!;

      final camel = StringUtils.toCamelCase(found.first.name);
      return '\${$camel}';
    });
  }
}
