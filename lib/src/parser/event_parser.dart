import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

import '../config/naming_strategy.dart';
import '../core/exceptions.dart';
import '../models/analytics_event.dart';
import '../models/analytics_parameter.dart';
import 'parameter_parser.dart';

/// Parses analytics events from YAML.
final class EventParser {
  /// Parses an event from a YAML node.
  static AnalyticsEvent parseEvent(
    String eventName,
    YamlNode valueNode, {
    required String domainName,
    required String filePath,
    required NamingStrategy naming,
    Map<String, AnalyticsParameter> sharedParameters = const {},
    bool enforceCentrallyDefinedParameters = false,
    bool preventEventParameterDuplicates = false,
    bool strictEventNames = true,
    SourceSpan? keySpan,
  }) {
    if (valueNode is! YamlMap) {
      throw AnalyticsParseException(
        'Event "$domainName.$eventName" must be a map.',
        filePath: filePath,
        span: valueNode.span,
      );
    }

    final eventData = valueNode;

    // Strict Event Name Validation: Check for interpolation
    if (strictEventNames &&
        (eventName.contains('{') || eventName.contains('}'))) {
      throw AnalyticsParseException(
        'Event name "$eventName" contains interpolation characters "{}" or "{}". '
        'Dynamic event names are discouraged as they lead to high cardinality.',
        filePath: filePath,
        span: keySpan ?? valueNode.span,
      );
    }

    final description =
        eventData['description'] as String? ?? 'No description provided';
    final customEventName = eventData['event_name'] as String?;

    if (customEventName != null) {
      final customEventNameNode = eventData.nodes['event_name'];
      if (strictEventNames &&
          (customEventName.contains('{') || customEventName.contains('}'))) {
        throw AnalyticsParseException(
          'Event name "$customEventName" contains interpolation characters "{}" or "{}". '
          'Dynamic event names are discouraged as they lead to high cardinality.',
          filePath: filePath,
          span: customEventNameNode?.span,
        );
      }
    }
    final identifier = eventData['identifier'] as String?;
    final deprecated = eventData['deprecated'] as bool? ?? false;
    final replacement = eventData['replacement'] as String?;
    final addedIn = eventData['added_in'] as String?;
    final deprecatedIn = eventData['deprecated_in'] as String?;

    final dualWriteToNode = eventData.nodes['dual_write_to'];
    List<String>? dualWriteTo;
    if (dualWriteToNode != null) {
      if (dualWriteToNode is YamlList) {
        dualWriteTo = dualWriteToNode.map((e) => e.toString()).toList();
      } else {
        throw AnalyticsParseException(
          'Field "dual_write_to" must be a list of strings.',
          filePath: filePath,
          span: dualWriteToNode.span,
        );
      }
    }

    final metaNode = eventData.nodes['meta'];
    Map<String, dynamic> meta = const {};
    if (metaNode != null) {
      if (metaNode is! YamlMap) {
        throw AnalyticsParseException(
          'The "meta" field must be a map.',
          filePath: filePath,
          span: metaNode.span,
        );
      }
      meta = metaNode.map((key, value) => MapEntry(key.toString(), value));
    }

    final rawParameters = eventData.nodes['parameters'];
    final parameters = <AnalyticsParameter>[];

    if (rawParameters != null) {
      if (rawParameters is! YamlMap) {
        throw AnalyticsParseException(
          'Parameters for event "$domainName.$eventName" must be a map.',
          filePath: filePath,
          span: rawParameters.span,
        );
      }

      final parsedParams = ParameterParser.parseParameters(
        rawParameters,
        domainName: domainName,
        eventName: eventName,
        filePath: filePath,
        naming: naming,
        sharedParameters: sharedParameters,
        enforceCentrallyDefinedParameters: enforceCentrallyDefinedParameters,
        preventEventParameterDuplicates: preventEventParameterDuplicates,
      );
      parameters.addAll(parsedParams);
    }

    return AnalyticsEvent(
      name: eventName,
      description: description,
      identifier: identifier,
      customEventName: customEventName,
      parameters: parameters,
      deprecated: deprecated,
      replacement: replacement,
      meta: meta,
      sourcePath: filePath,
      lineNumber: valueNode.span.start.line + 1,
      addedIn: addedIn,
      deprecatedIn: deprecatedIn,
      dualWriteTo: dualWriteTo,
    );
  }
}
