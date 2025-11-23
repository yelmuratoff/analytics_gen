import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';

import '../../config/analytics_config.dart';
import '../../models/analytics_event.dart';
import '../../util/event_naming.dart';
import '../../util/string_utils.dart';
import '../../util/type_mapper.dart';
import 'base_renderer.dart';
import 'enum_renderer.dart';

/// Renders analytics event domain files.
class EventRenderer extends BaseRenderer {
  /// Creates a new event renderer.
  const EventRenderer(this.config);

  /// The analytics configuration.
  final AnalyticsConfig config;

  static final _placeholderRegex = RegExp(r'\{([^}]+)\}');

  /// Renders a domain file with event methods.
  String renderDomainFile(
    String domainName,
    AnalyticsDomain domain,
    Map<String, AnalyticsDomain> allDomains,
  ) {
    final buffer = StringBuffer();

    // File header
    buffer.write(renderFileHeader());
    buffer.write(renderImports(['package:analytics_gen/analytics_gen.dart']));

    // Generate Enums
    buffer.write(const EnumRenderer().renderEnums(domainName, domain));

    // Generate mixin
    buffer.write(renderDomainMixin(domainName, domain, allDomains));

    return buffer.toString();
  }

  /// Renders a domain mixin with event methods.
  String renderDomainMixin(
    String domainName,
    AnalyticsDomain domain,
    Map<String, AnalyticsDomain> allDomains,
  ) {
    final buffer = StringBuffer();
    final className = 'Analytics${StringUtils.capitalizePascal(domainName)}';

    buffer.writeln('/// Generated mixin for $domainName analytics events');
    buffer.writeln('mixin $className on AnalyticsBase {');

    for (final event in domain.events) {
      buffer.write(_renderEventMethod(domainName, event, allDomains));
    }

    buffer.writeln('}');

    return buffer.toString();
  }

  String _renderEventMethod(
    String domainName,
    AnalyticsEvent event,
    Map<String, AnalyticsDomain> allDomains,
  ) {
    final buffer = StringBuffer();
    final methodName = EventNaming.buildLoggerMethodName(
      domainName,
      event.name,
    );

    // Deprecation annotation
    if (event.deprecated) {
      final message = _buildDeprecationMessage(event);
      buffer.writeln("  @Deprecated('$message')");
    } else {
      final eventName =
          EventNaming.resolveEventName(domainName, event, config.naming);
      final interpolatedEventName = _replacePlaceholdersWithInterpolation(
        eventName,
        event.parameters,
      );
      if (interpolatedEventName.contains(r'${')) {
        // Note: If strict_event_names is true, the YamlParser would have already
        // rejected this event. This check handles the case where strict mode
        // is disabled but we still want to warn about high cardinality.
        buffer.writeln(
            "  @Deprecated('This event uses string interpolation in its name, which causes high cardinality. Use parameters instead.')");
      }
    }

    // Documentation
    buffer.writeln('  /// ${event.description}');
    buffer.writeln('  ///');

    final includeDescription =
        config.includeEventDescription && event.description.isNotEmpty;

    if (event.parameters.isNotEmpty) {
      buffer.writeln('  /// Parameters:');
      for (final param in event.parameters) {
        final isEnum = param.type == 'string' &&
            param.allowedValues != null &&
            param.allowedValues!.isNotEmpty;
        final typeName = isEnum
            ? const EnumRenderer().buildEnumName(domainName, event, param)
            : DartTypeMapper.toDartType(param.type);

        if (param.description != null) {
          buffer.writeln(
            '  /// - `${param.name}`: $typeName${param.isNullable ? '?' : ''} - ${param.description}',
          );
        } else {
          buffer.writeln(
            '  /// - `${param.name}`: $typeName${param.isNullable ? '?' : ''}',
          );
        }
      }
    }

    // Method signature
    buffer.write('  void $methodName(');

    if (event.parameters.isNotEmpty) {
      buffer.writeln('{');
      for (final param in event.parameters) {
        final isEnum = param.type == 'string' &&
            param.allowedValues != null &&
            param.allowedValues!.isNotEmpty;

        String dartType;
        if (isEnum) {
          dartType =
              const EnumRenderer().buildEnumName(domainName, event, param);
        } else {
          dartType = DartTypeMapper.toDartType(param.type);
        }

        final nullableType = param.isNullable ? '$dartType?' : dartType;
        final required = param.isNullable ? '' : 'required ';
        final camelParam = StringUtils.toCamelCase(param.codeName);
        buffer.writeln('    $required$nullableType $camelParam,');
      }
      // Add optional parameters override
      final hasParametersParam = event.parameters
          .any((p) => StringUtils.toCamelCase(p.codeName) == 'parameters');
      final parametersArgName =
          hasParametersParam ? 'analyticsParameters' : 'parameters';
      buffer.writeln('    Map<String, Object?>? $parametersArgName,');

      buffer.writeln('  }) {');
      buffer.writeln();

      for (final param in event.parameters) {
        final isEnum = param.type == 'string' &&
            param.allowedValues != null &&
            param.allowedValues!.isNotEmpty;

        if (!isEnum) {
          final allowedValues = param.allowedValues;
          if (allowedValues != null && allowedValues.isNotEmpty) {
            final camelParam = StringUtils.toCamelCase(param.codeName);
            final constName =
                'allowed${StringUtils.capitalizePascal(camelParam)}Values';
            final encodedValues = encodeAllowedValues(allowedValues);
            final joinedValues = joinAllowedValues(allowedValues);
            final dartType = DartTypeMapper.toDartType(param.type);

            buffer.write(renderAllowedValuesCheck(
              camelParam: camelParam,
              constName: constName,
              encodedValues: encodedValues,
              joinedValues: joinedValues,
              isNullable: param.isNullable,
              type: dartType,
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
          buffer.write(renderValidationChecks(
            camelParam: camelParam,
            isNullable: param.isNullable,
            regex: param.regex,
            minLength: param.minLength,
            maxLength: param.maxLength,
            min: param.min,
            max: param.max,
          ));
        }
      }
    } else {
      // Add optional parameters override even if no params
      buffer.writeln('{Map<String, Object?>? parameters}) {');
    }

    // Method body
    final eventName =
        EventNaming.resolveEventName(domainName, event, config.naming);
    final interpolatedEventName = _replacePlaceholdersWithInterpolation(
      eventName,
      event.parameters,
    );

    final hasParametersParam = event.parameters
        .any((p) => StringUtils.toCamelCase(p.codeName) == 'parameters');
    final parametersArgName =
        hasParametersParam ? 'analyticsParameters' : 'parameters';

    if (event.parameters.isNotEmpty || includeDescription) {
      buffer.writeln(
          '    final eventParameters = $parametersArgName ?? <String, Object?>{');

      if (includeDescription) {
        buffer.writeln(
          "      'description': '${StringUtils.escapeSingleQuoted(event.description)}',",
        );
      }
      for (final param in event.parameters) {
        final camelParam = StringUtils.toCamelCase(param.codeName);
        final isEnum = param.type == 'string' &&
            param.allowedValues != null &&
            param.allowedValues!.isNotEmpty;

        final valueAccess = isEnum
            ? (param.isNullable ? '$camelParam?.value' : '$camelParam.value')
            : camelParam;

        if (param.isNullable) {
          buffer.writeln(
            '      if ($camelParam != null) "${param.name}": $valueAccess,',
          );
        } else {
          buffer.writeln('      "${param.name}": $valueAccess,');
        }
      }
      buffer.writeln('    };');
      buffer.writeln();

      buffer.writeln('    logger.logEvent(');
      buffer.writeln('      name: "$interpolatedEventName",');
      buffer.writeln('      parameters: eventParameters,');
      buffer.writeln('    );');

      if (event.dualWriteTo != null) {
        for (final target in event.dualWriteTo!) {
          buffer.writeln();
          buffer.writeln('    // Dual-write to: $target');

          final methodCall = _tryGenerateMethodCall(
            target,
            domainName,
            event,
            allDomains,
            parametersArgName: parametersArgName,
          );

          if (methodCall != null) {
            buffer.writeln('    $methodCall');
          } else {
            final resolvedName = _resolveTargetEventName(target, allDomains);
            buffer.writeln('    logger.logEvent(');
            buffer.writeln('      name: "$resolvedName",');
            buffer.writeln('      parameters: eventParameters,');
            buffer.writeln('    );');
          }
        }
      }
    } else {
      buffer.writeln(
          '    final eventParameters = parameters ?? const <String, Object?>{};');
      buffer.writeln('    logger.logEvent(');
      buffer.writeln('      name: "$interpolatedEventName",');
      buffer.writeln('      parameters: eventParameters,');
      buffer.writeln('    );');

      if (event.dualWriteTo != null) {
        for (final target in event.dualWriteTo!) {
          buffer.writeln();
          buffer.writeln('    // Dual-write to: $target');

          final methodCall = _tryGenerateMethodCall(
            target,
            domainName,
            event,
            allDomains,
            parametersArgName: parametersArgName,
          );

          if (methodCall != null) {
            buffer.writeln('    $methodCall');
          } else {
            final resolvedName = _resolveTargetEventName(target, allDomains);
            buffer.writeln('    logger.logEvent(');
            buffer.writeln('      name: "$resolvedName",');
            buffer.writeln('      parameters: eventParameters,');
            buffer.writeln('    );');
          }
        }
      }
    }

    buffer.writeln('  }');
    buffer.writeln();

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

      if (targetParam.type == sourceParam.type) {
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

  String _buildDeprecationMessage(AnalyticsEvent event) {
    if (event.replacement == null || event.replacement!.isEmpty) {
      return 'This analytics event is deprecated.';
    }

    final methodName =
        EventNaming.buildLoggerMethodNameFromReplacement(event.replacement!);
    if (methodName != null) {
      return 'Use $methodName instead.';
    }

    return 'Use ${event.replacement} instead.';
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
