import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';

import '../../../util/event_naming.dart';
import '../../../util/string_utils.dart';
import '../../../util/type_mapper.dart';
import '../../utils/code_buffer.dart';
import '../../validators/cross_domain_validator.dart';
import 'validation_renderer.dart';

/// Renders the body of event logger methods.
class EventBodyRenderer {
  /// Creates a new event body renderer.
  const EventBodyRenderer(this.config);

  /// The analytics configuration.
  final AnalyticsConfig config;

  /// Renders the method body.
  String renderBody(
    String domainName,
    AnalyticsEvent event,
    Map<String, AnalyticsDomain> allDomains, {
    int indent = 0,
    Map<String, String> regexPatterns = const {},
  }) {
    final buffer = CodeBuffer(initialIndent: indent);

    // 1. Validation Logic
    _renderValidations(buffer, domainName, event, regexPatterns);

    // 2. Prepare event name
    final eventName =
        EventNaming.resolveEventName(domainName, event, config.naming);
    final interpolatedEventName = event.interpolatedName ?? eventName;

    // 3. Prepare parameters map
    final includeDescription =
        config.includeEventDescription && event.description.isNotEmpty;

    final hasParametersParam = event.parameters
        .any((p) => StringUtils.toCamelCase(p.codeName) == 'parameters');
    final parametersArgName =
        hasParametersParam ? 'analyticsParameters' : 'parameters';

    if (event.parameters.isNotEmpty || includeDescription) {
      buffer.writeln('final eventParameters = <String, Object?>{');

      if (includeDescription) {
        buffer.writeln(
          "  'description': '${StringUtils.escapeSingleQuoted(event.description)}',",
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
            '  if ($camelParam != null) "${param.name}": $valueAccess,',
          );
        } else {
          buffer.writeln('  "${param.name}": $valueAccess,');
        }
      }
      buffer.writeln('}..addAll($parametersArgName ?? const {});');
      buffer.writeln();

      buffer.writeln('logger.logEvent(');
      buffer.writeln('  name: "$interpolatedEventName",');
      buffer.writeln('  parameters: eventParameters,');
      buffer.writeln(');');

      // 4. Dual write logic
      if (event.dualWriteTo != null) {
        _renderDualWrite(
          buffer,
          domainName,
          event,
          allDomains,
          parametersArgName,
          eventParametersVar: 'eventParameters',
        );
      }
    } else {
      buffer.writeln(
          'final eventParameters = <String, Object?>{}..addAll(parameters ?? const {});');
      buffer.writeln('logger.logEvent(');
      buffer.writeln('  name: "$interpolatedEventName",');
      buffer.writeln('  parameters: eventParameters,');
      buffer.writeln(');');

      if (event.dualWriteTo != null) {
        _renderDualWrite(
          buffer,
          domainName,
          event,
          allDomains,
          parametersArgName,
          eventParametersVar: 'eventParameters',
        );
      }
    }

    return buffer.toString();
  }

  void _renderValidations(
    CodeBuffer buffer,
    String domainName,
    AnalyticsEvent event,
    Map<String, String> regexPatterns,
  ) {
    final validator = const ValidationRenderer();

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

          buffer.writeln(validator.renderAllowedValuesCheck(
            camelParam: camelParam,
            constName: constName,
            encodedValues: encodedValues,
            joinedValues: joinedValues,
            isNullable: param.isNullable,
            type: dartType,
            indent: 0,
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
        // Check if regex is cached at mixin level
        final regexFieldName = '_${camelParam}Regex';
        final usesCachedRegex =
            param.regex != null && regexPatterns.containsKey(regexFieldName);

        buffer.writeln(validator.renderValidationChecks(
          camelParam: camelParam,
          isNullable: param.isNullable,
          regex: param.regex,
          minLength: param.minLength,
          maxLength: param.maxLength,
          min: param.min,
          max: param.max,
          indent: 0,
          cachedRegexFieldName: usesCachedRegex ? regexFieldName : null,
        ));
      }
    }
  }

  void _renderDualWrite(
    CodeBuffer buffer,
    String domainName,
    AnalyticsEvent event,
    Map<String, AnalyticsDomain> allDomains,
    String parametersArgName, {
    required String eventParametersVar,
  }) {
    final validator = CrossDomainValidator(config);

    for (final target in event.dualWriteTo!) {
      buffer.writeln();
      buffer.writeln('// Dual-write to: $target');

      final result = validator.validate(
        target,
        domainName,
        event,
        allDomains,
        parametersArgName: parametersArgName,
      );

      if (result.isValid) {
        final args = result.arguments!.entries.map((e) {
          if (e.key == 'parameters') return 'parameters: ${e.value}';
          return '${StringUtils.toCamelCase(e.key)}: ${e.value}';
        }).join(', ');
        buffer.writeln('${result.methodName}($args);');
      } else {
        buffer.writeln('logger.logEvent(');
        buffer.writeln('  name: "${result.fallbackEventName}",');
        buffer.writeln('  parameters: $eventParametersVar,');
        buffer.writeln(');');
      }
    }
  }
}
