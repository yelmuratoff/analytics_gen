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
  String renderDomainFile(String domainName, AnalyticsDomain domain) {
    final buffer = StringBuffer();

    // File header
    buffer.write(renderFileHeader());
    buffer.write(renderImports(['package:analytics_gen/analytics_gen.dart']));

    // Generate Enums
    buffer.write(const EnumRenderer().renderEnums(domainName, domain));

    // Generate mixin
    buffer.write(renderDomainMixin(domainName, domain));

    return buffer.toString();
  }

  /// Renders a domain mixin with event methods.
  String renderDomainMixin(String domainName, AnalyticsDomain domain) {
    final buffer = StringBuffer();
    final className = 'Analytics${StringUtils.capitalizePascal(domainName)}';

    buffer.writeln('/// Generated mixin for $domainName analytics events');
    buffer.writeln('mixin $className on AnalyticsBase {');

    for (final event in domain.events) {
      buffer.write(_renderEventMethod(domainName, event));
    }

    buffer.writeln('}');

    return buffer.toString();
  }

  String _renderEventMethod(String domainName, AnalyticsEvent event) {
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
            : param.type;

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
          dartType = const EnumRenderer().buildEnumName(domainName, event, param);
        } else {
          dartType = DartTypeMapper.toDartType(param.type);
        }

        final nullableType = param.isNullable ? '$dartType?' : dartType;
        final required = param.isNullable ? '' : 'required ';
        final camelParam = StringUtils.toCamelCase(param.codeName);
        buffer.writeln('    $required$nullableType $camelParam,');
      }
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
      buffer.writeln(') {');
    }

    // Method body
    final eventName =
        EventNaming.resolveEventName(domainName, event, config.naming);
    final interpolatedEventName = _replacePlaceholdersWithInterpolation(
      eventName,
      event.parameters,
    );

    buffer.writeln('    logger.logEvent(');
    buffer.writeln('      name: "$interpolatedEventName",');

    if (event.parameters.isNotEmpty || includeDescription) {
      buffer.writeln('      parameters: <String, Object?>{');

      if (includeDescription) {
        buffer.writeln(
          "        'description': '${StringUtils.escapeSingleQuoted(event.description)}',",
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
            '        if ($camelParam != null) "${param.name}": $valueAccess,',
          );
        } else {
          buffer.writeln('        "${param.name}": $valueAccess,');
        }
      }
      buffer.writeln('      },');
    } else {
      buffer.writeln('      parameters: const {},');
    }

    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();

    return buffer.toString();
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
