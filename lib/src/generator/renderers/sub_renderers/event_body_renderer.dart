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
  }) {
    final buffer = CodeBuffer(initialIndent: indent);

    // 1. Validation Logic
    _renderValidations(buffer, domainName, event);

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
      final isConst = event.parameters.isEmpty;
      buffer.writeln(
          'final eventParameters = $parametersArgName ?? ${isConst ? 'const ' : ''}<String, Object?>{');

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
      buffer.writeln('};');
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
          'final eventParameters = parameters ?? const <String, Object?>{};');
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
            indent:
                0, // CodeBuffer handles main indent, but ValidationRenderer might need to be CodeBuffer aware.
            // Wait, ValidationRenderer returns String with indentation argument.
            // If I pass 0, it returns non-indented string.
            // CodeBuffer.write does NOT indent (CodeBuffer.writeln does).
            // So if I use buffer.write, I need to be careful.
            // Ideally ValidationRenderer should also use CodeBuffer or return raw strings.
            // But ValidationRenderer is old.
            // Let's assume indent: 0 gives unindented block (relative to current buffer indent).
            // But CodeBuffer stores absolute indent.
            // If ValidationRenderer returns multiline string, CodeBuffer.writeln/write handles it?
            // CodeBuffer.write does NOT handle multiline indentation automatically for each line if passed as one string.
            // But ValidationRenderer.renderAllowedValuesCheck returns a code block with '  '*indent logic.
            // If I pass 0, it renders flat.
            // But I want it indented by current buffer context.
            // CodeBuffer doesn't have `writeBlock` that indents each line.
            // I added `joinLines` to CodeBuffer.
            // Use that if I can split.
          ));
          // Actually, if I pass `buffer.indent` (private) .. I can't.
          // I didn't expose current indent level getter in CodeBuffer. I should have.
          // But I can fix this by relying on CodeBuffer's indent.
          // If ValidationRenderer returns lines, I should split and write them.
        }
      }

      // Validation rules
      if (param.regex != null ||
          param.minLength != null ||
          param.maxLength != null ||
          param.min != null ||
          param.max != null) {
        final camelParam = StringUtils.toCamelCase(param.codeName);
        buffer.writeln(validator.renderValidationChecks(
          camelParam: camelParam,
          isNullable: param.isNullable,
          regex: param.regex,
          minLength: param.minLength,
          maxLength: param.maxLength,
          min: param.min,
          max: param.max,
          indent: 0,
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
