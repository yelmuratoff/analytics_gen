import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';
import 'package:analytics_gen/src/util/string_utils.dart';

/// Serializes the analytics tracking plan into Dart code.
class PlanSerializer {
  /// Creates a new plan serializer.
  const PlanSerializer();

  /// Generates the static `plan` field for the Analytics class.
  String generatePlanField(Map<String, AnalyticsDomain> domains) {
    final buffer = StringBuffer();
    buffer.writeln('  /// Runtime view of the generated tracking plan.');
    buffer.writeln(
      '  static const List<AnalyticsDomain> plan = <AnalyticsDomain>[',
    );

    final sortedDomains = domains.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in sortedDomains) {
      buffer.write(_analyticsDomainPlanEntry(entry.value));
    }

    buffer.writeln('  ];');
    return buffer.toString();
  }

  String _analyticsDomainPlanEntry(AnalyticsDomain domain) {
    final buffer = StringBuffer();
    buffer.writeln('    AnalyticsDomain(');
    buffer.writeln(
        "      name: '${StringUtils.escapeSingleQuoted(domain.name)}',");
    buffer.writeln('      events: <AnalyticsEvent>[');

    for (final event in domain.events) {
      buffer.write(_analyticsEventPlanEntry(event));
    }

    buffer.writeln('      ],');
    buffer.writeln('    ),');
    return buffer.toString();
  }

  String _analyticsEventPlanEntry(AnalyticsEvent event) {
    final buffer = StringBuffer();
    buffer.writeln('        AnalyticsEvent(');
    buffer.writeln(
        "          name: '${StringUtils.escapeSingleQuoted(event.name)}',");
    buffer.writeln(
      "          description: '${StringUtils.escapeSingleQuoted(event.description)}',",
    );
    if (event.identifier != null) {
      buffer.writeln(
        "          identifier: '${StringUtils.escapeSingleQuoted(event.identifier!)}',",
      );
    }
    if (event.customEventName != null) {
      buffer.writeln(
        "          customEventName: '${StringUtils.escapeSingleQuoted(event.customEventName!)}',",
      );
    }
    buffer.writeln('          deprecated: ${event.deprecated},');
    if (event.replacement != null) {
      buffer.writeln(
        "          replacement: '${StringUtils.escapeSingleQuoted(event.replacement!)}',",
      );
    }
    if (event.meta.isNotEmpty) {
      buffer.writeln('          meta: <String, Object?>{');
      final entries = event.meta.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      for (final entry in entries) {
        final valueString = _dartLiteral(entry.value);
        buffer.writeln(
          "            '${StringUtils.escapeSingleQuoted(entry.key)}': $valueString,",
        );
      }
      buffer.writeln('          },');
    }
    buffer.writeln('          parameters: <AnalyticsParameter>[');

    for (final param in event.parameters) {
      buffer.write(_analyticsParameterPlanEntry(param));
    }

    buffer.writeln('          ],');
    buffer.writeln('        ),');
    return buffer.toString();
  }

  String _analyticsParameterPlanEntry(AnalyticsParameter param) {
    final buffer = StringBuffer();
    buffer.writeln('            AnalyticsParameter(');
    buffer.writeln(
        "              name: '${StringUtils.escapeSingleQuoted(param.name)}',");
    if (param.codeName != param.name) {
      buffer.writeln(
        "              codeName: '${StringUtils.escapeSingleQuoted(param.codeName)}',",
      );
    }
    buffer.writeln(
        "              type: '${StringUtils.escapeSingleQuoted(param.type)}',");
    buffer.writeln('              isNullable: ${param.isNullable},');
    if (param.description != null) {
      buffer.writeln(
        "              description: '${StringUtils.escapeSingleQuoted(param.description!)}',",
      );
    }
    if (param.allowedValues != null && param.allowedValues!.isNotEmpty) {
      buffer.writeln('              allowedValues: <Object>[');
      for (final value in param.allowedValues!) {
        final valueString = _dartLiteral(value);
        buffer.writeln(
          '                $valueString,',
        );
      }
      buffer.writeln('              ],');
    }
    if (param.meta.isNotEmpty) {
      buffer.writeln('              meta: <String, Object?>{');
      final entries = param.meta.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      for (final entry in entries) {
        final valueString = _dartLiteral(entry.value);
        buffer.writeln(
          "                '${StringUtils.escapeSingleQuoted(entry.key)}': $valueString,",
        );
      }
      buffer.writeln('              },');
    }
    buffer.writeln('            ),');
    return buffer.toString();
  }

  String _dartLiteral(Object? value) {
    if (value == null) return 'null';
    if (value is bool) return value ? 'true' : 'false';
    if (value is num) return value.toString();
    if (value is String) {
      return "'${StringUtils.escapeSingleQuoted(value)}'";
    }

    if (value is Iterable) {
      final buffer = StringBuffer('<Object?>[');
      var first = true;
      for (final v in value) {
        if (!first) buffer.write(', ');
        first = false;
        buffer.write(_dartLiteral(v));
      }
      buffer.write(']');
      return buffer.toString();
    }

    if (value is Map) {
      final entries = value.entries.toList()
        ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
      final buffer = StringBuffer('<String, Object?>{');
      var first = true;
      for (final entry in entries) {
        if (entry.key is! String) {
          throw StateError(
            'Plan meta value contains a non-string key (${entry.key.runtimeType}). '
            'This should have been rejected during YAML parsing.',
          );
        }
        if (!first) buffer.write(', ');
        first = false;
        final key = entry.key as String;
        buffer.write(
          "'${StringUtils.escapeSingleQuoted(key)}': ${_dartLiteral(entry.value)}",
        );
      }
      buffer.write('}');
      return buffer.toString();
    }

    throw StateError(
      'Unsupported value type in generated plan: ${value.runtimeType}. '
      'This should have been rejected during YAML parsing.',
    );
  }
}
