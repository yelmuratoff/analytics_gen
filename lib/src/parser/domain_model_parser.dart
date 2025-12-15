import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';
import 'package:analytics_gen/src/parser/event_parser.dart';
import 'package:yaml/yaml.dart';

import '../config/naming_strategy.dart';
import '../core/exceptions.dart';

/// Parses analytics domains from YAML.
final class DomainModelParser {
  /// Parses a domain from a YAML node.
  static AnalyticsDomain parseDomain(
    String domainName,
    YamlNode valueNode, {
    required String filePath,
    required NamingStrategy naming,
    Map<String, AnalyticsParameter> sharedParameters = const {},
    bool enforceCentrallyDefinedParameters = false,
    bool preventEventParameterDuplicates = false,
    bool strictEventNames = true,
    void Function(AnalyticsParseException)? onError,
  }) {
    if (valueNode is! YamlMap) {
      throw AnalyticsParseException(
        'Domain "$domainName" must be a map of events.',
        filePath: filePath,
        span: valueNode.span,
      );
    }

    final eventsYaml = valueNode;
    final events = <AnalyticsEvent>[];

    final sortedEvents = eventsYaml.nodes.entries.toList()
      ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));

    for (final entry in sortedEvents) {
      final keyNode = entry.key as YamlNode;
      final eventName = keyNode.toString();
      final eventValue = entry.value;

      try {
        final event = EventParser.parseEvent(
          eventName,
          eventValue,
          domainName: domainName,
          filePath: filePath,
          naming: naming,
          sharedParameters: sharedParameters,
          enforceCentrallyDefinedParameters: enforceCentrallyDefinedParameters,
          preventEventParameterDuplicates: preventEventParameterDuplicates,
          strictEventNames: strictEventNames,
          keySpan: keyNode.span,
        );
        events.add(event);
      } on AnalyticsParseException catch (e) {
        if (onError != null) {
          onError(e);
        } else {
          rethrow;
        }
      } catch (e) {
        final error = AnalyticsParseException(
          e.toString(),
          filePath: filePath,
          innerError: e,
          span: keyNode.span,
        );
        if (onError != null) {
          onError(error);
        } else {
          throw error;
        }
      }
    }

    return AnalyticsDomain(
      name: domainName,
      events: events,
    );
  }
}
