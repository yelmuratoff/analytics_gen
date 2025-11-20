import '../../config/analytics_config.dart';
import '../../core/exceptions.dart';
import '../../models/analytics_event.dart';
import '../../util/event_naming.dart';
import '../../util/string_utils.dart';
import '../../util/type_mapper.dart';

class EventRenderer {
  final AnalyticsConfig config;

  EventRenderer(this.config);

  String renderDomainFile(String domainName, AnalyticsDomain domain) {
    final buffer = StringBuffer();

    // File header
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// ignore_for_file: type=lint, unused_import');
    buffer.writeln(
      '// ignore_for_file: directives_ordering, unnecessary_string_interpolations',
    );
    buffer.writeln('// coverage:ignore-file');
    buffer.writeln();
    buffer.writeln("import 'package:analytics_gen/analytics_gen.dart';");
    buffer.writeln();

    // Generate mixin
    buffer.write(renderDomainMixin(domainName, domain));

    return buffer.toString();
  }

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
        if (config.strictEventNames) {
          throw AnalyticsGenerationException(
            'Event "$domainName.${event.name}" uses string interpolation in its name ("$eventName"). '
            'This is forbidden when strict_event_names is true to prevent high cardinality.',
          );
        }
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
        if (param.description != null) {
          buffer.writeln(
            '  /// - `${param.name}`: ${param.type}${param.isNullable ? '?' : ''} - ${param.description}',
          );
        } else {
          buffer.writeln(
            '  /// - `${param.name}`: ${param.type}${param.isNullable ? '?' : ''}',
          );
        }
      }
    }

    // Method signature
    buffer.write('  void $methodName(');

    if (event.parameters.isNotEmpty) {
      buffer.writeln('{');
      for (final param in event.parameters) {
        final dartType = DartTypeMapper.toDartType(param.type);
        final nullableType = param.isNullable ? '$dartType?' : dartType;
        final required = param.isNullable ? '' : 'required ';
        final camelParam = StringUtils.toCamelCase(param.codeName);
        buffer.writeln('    $required$nullableType $camelParam,');
      }
      buffer.writeln('  }) {');
      buffer.writeln();

      for (final param in event.parameters) {
        final allowedValues = param.allowedValues;
        if (allowedValues != null && allowedValues.isNotEmpty) {
          final camelParam = StringUtils.toCamelCase(param.codeName);
          final constName =
              'allowed${StringUtils.capitalizePascal(camelParam)}Values';
          final encodedValues = allowedValues
              .map((value) => '\'${StringUtils.escapeSingleQuoted(value)}\'')
              .join(', ');
          final joinedValues = allowedValues.join(', ');

          buffer.write(_renderAllowedValuesCheck(
            camelParam: camelParam,
            constName: constName,
            encodedValues: encodedValues,
            joinedValues: joinedValues,
            isNullable: param.isNullable,
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
        if (param.isNullable) {
          buffer.writeln(
            '        if ($camelParam != null) "${param.name}": $camelParam,',
          );
        } else {
          buffer.writeln('        "${param.name}": $camelParam,');
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

  String _renderAllowedValuesCheck({
    required String camelParam,
    required String constName,
    required String encodedValues,
    required String joinedValues,
    required bool isNullable,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('    const $constName = <String>{$encodedValues};');

    final condition = isNullable
        ? 'if ($camelParam != null && !$constName.contains($camelParam)) {'
        : 'if (!$constName.contains($camelParam)) {';

    buffer.writeln('    $condition');
    buffer.writeln('      throw ArgumentError.value(');
    buffer.writeln('        $camelParam,');
    buffer.writeln("        '$camelParam',");
    buffer.writeln("        'must be one of $joinedValues',");
    buffer.writeln('      );');
    buffer.writeln('    }');
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

  static final _placeholderRegex = RegExp(r'\{([^}]+)\}');

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
