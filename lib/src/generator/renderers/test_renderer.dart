import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';

import '../../config/analytics_config.dart';
import '../../models/analytics_event.dart';
import '../../util/event_naming.dart';
import '../../util/string_utils.dart';
import '../../util/type_mapper.dart';
import 'base_renderer.dart';
import 'enum_renderer.dart';

/// Renders a Dart test file to verify generated analytics events.
class TestRenderer extends BaseRenderer {
  /// Creates a new test renderer.
  const TestRenderer(
    this.config, {
    this.isFlutter = false,
  });

  /// The analytics configuration.
  final AnalyticsConfig config;

  /// Whether the project is a Flutter project.
  final bool isFlutter;

  /// Renders the test file content.
  String render(Map<String, AnalyticsDomain> domains) {
    final buffer = StringBuffer();

    buffer.write(renderFileHeader());

    final imports = <String>[
      if (isFlutter)
        'package:flutter_test/flutter_test.dart'
      else
        'package:test/test.dart',
      'package:analytics_gen/analytics_gen.dart',
      '../lib/${config.outputPath}/analytics.dart',
      '../lib/${config.outputPath}/generated_events.dart',
    ];

    // Collect imports from parameters
    for (final domain in domains.values) {
      for (final event in domain.events) {
        for (final param in event.parameters) {
          if (param.dartImport != null) {
            imports.add(param.dartImport!);
          }
        }
      }
    }

    buffer.write(renderImports(imports));

    buffer.writeln('void main() {');
    buffer.writeln("  group('Analytics Plan Tests', () {");
    buffer.writeln('    late Analytics analytics;');
    buffer.writeln();
    buffer.writeln('    setUp(() {');
    buffer.writeln('      analytics = Analytics(MockAnalyticsService());');
    buffer.writeln('    });');
    buffer.writeln();

    for (final domain in domains.values) {
      buffer.writeln("    group('${domain.name}', () {");
      for (final event in domain.events) {
        _renderEventTest(buffer, domain, event);
      }
      buffer.writeln('    });');
    }

    buffer.writeln('  });');
    buffer.writeln('}');

    return buffer.toString();
  }

  void _renderEventTest(
    StringBuffer buffer,
    AnalyticsDomain domain,
    AnalyticsEvent event,
  ) {
    final methodName = EventNaming.buildLoggerMethodName(
      domain.name,
      event.name,
    );

    buffer.writeln("      test('$methodName constructs correctly', () {");
    buffer.writeln('        expect(() => analytics.$methodName(');

    for (final param in event.parameters) {
      if (!param.isNullable) {
        final value = _generateValue(domain, event, param);
        final camelParam = StringUtils.toCamelCase(param.codeName);
        buffer.writeln('          $camelParam: $value,');
      }
    }

    buffer.writeln('        ), returnsNormally);');
    buffer.writeln('      });');
  }

  String _generateValue(
    AnalyticsDomain domain,
    AnalyticsEvent event,
    AnalyticsParameter param,
  ) {
    if (param.type == 'string' &&
        param.allowedValues != null &&
        param.allowedValues!.isNotEmpty) {
      final enumName =
          const EnumRenderer().buildEnumName(domain.name, event, param);
      final firstValue = param.allowedValues!.first.toString();
      final enumIdentifier = const EnumRenderer().toEnumIdentifier(firstValue);
      return '$enumName.$enumIdentifier';
    }

    if (param.allowedValues != null && param.allowedValues!.isNotEmpty) {
      final value = param.allowedValues!.first;
      if (value is String) return "'$value'";
      return value.toString();
    }

    if (param.dartType != null) {
      // Assume Enums for custom Dart types
      return '${param.dartType}.values.first';
    }

    final dartType = DartTypeMapper.toDartType(param.type);

    switch (dartType) {
      case 'String':
        return _generateStringValue(param);
      case 'int':
        return _generateIntValue(param);
      case 'double':
        return _generateDoubleValue(param);
      case 'bool':
        return 'true';
      default:
        if (dartType.startsWith('List')) {
          return 'const []';
        }
        return 'null'; // Should not happen for non-nullable without defaults
    }
  }

  String _generateStringValue(AnalyticsParameter param) {
    // Note: Regex generation is not yet supported.
    // If a parameter has a regex pattern, this simple value might fail validation.
    // In the future, we could use a library like `fare` to generate matching strings.
    var value = 'test';
    if (param.minLength != null) {
      while (value.length < param.minLength!) {
        value += 'test';
      }
    }
    if (param.maxLength != null && value.length > param.maxLength!) {
      value = value.substring(0, param.maxLength!);
    }
    return "'$value'";
  }

  String _generateIntValue(AnalyticsParameter param) {
    if (param.min != null) return param.min.toString();
    if (param.max != null) return param.max.toString();
    return '42';
  }

  String _generateDoubleValue(AnalyticsParameter param) {
    if (param.min != null) return param.min.toString();
    if (param.max != null) return param.max.toString();
    return '42.0';
  }
}
