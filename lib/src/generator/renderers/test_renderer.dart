import '../../config/analytics_config.dart';
import '../../models/analytics_event.dart';
import '../../util/event_naming.dart';
import '../../util/string_utils.dart';
import '../../util/type_mapper.dart';

/// Renders a Dart test file to verify generated analytics events.
class TestRenderer {
  /// Creates a new test renderer.
  const TestRenderer(this.config);

  /// The analytics configuration.
  final AnalyticsConfig config;

  /// Renders the test file content.
  String render(Map<String, AnalyticsDomain> domains) {
    final buffer = StringBuffer();

    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln();
    buffer.writeln("import 'package:test/test.dart';");
    buffer.writeln("import 'package:analytics_gen/analytics_gen.dart';");
    buffer.writeln("import '../lib/${config.outputPath}/analytics.dart';");
    buffer
        .writeln("import '../lib/${config.outputPath}/generated_events.dart';");
    buffer.writeln();

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
        final value = _generateValue(param);
        final camelParam = StringUtils.toCamelCase(param.codeName);
        buffer.writeln('          $camelParam: $value,');
      }
    }

    buffer.writeln('        ), returnsNormally);');
    buffer.writeln('      });');
  }

  String _generateValue(AnalyticsParameter param) {
    if (param.allowedValues != null && param.allowedValues!.isNotEmpty) {
      final value = param.allowedValues!.first;
      if (value is String) return "'$value'";
      return value.toString();
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
