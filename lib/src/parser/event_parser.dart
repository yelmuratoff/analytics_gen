import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

import '../config/naming_strategy.dart';
import '../core/exceptions.dart';
import '../models/analytics_event.dart';
import '../models/analytics_parameter.dart';
import '../util/string_utils.dart';
import '../util/yaml_keys.dart';
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
        eventData[YamlKeys.description] as String? ?? 'No description provided';
    final customEventName = eventData[YamlKeys.eventName] as String?;

    if (customEventName != null) {
      final customEventNameNode = eventData.nodes[YamlKeys.eventName];
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
    final identifier = eventData[YamlKeys.identifier] as String?;
    final deprecated = eventData[YamlKeys.deprecated] as bool? ?? false;
    final replacement = eventData[YamlKeys.replacement] as String?;
    final addedIn = eventData[YamlKeys.addedIn] as String?;
    final deprecatedIn = eventData[YamlKeys.deprecatedIn] as String?;

    final dualWriteToNode = eventData.nodes[YamlKeys.dualWriteTo];
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

    final metaNode = eventData.nodes[YamlKeys.meta];
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

    final rawParameters = eventData.nodes[YamlKeys.parameters];
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

    String? interpolatedName;
    // Resolve effective name to check for placeholders
    final effectiveName =
        (customEventName != null && customEventName.isNotEmpty)
            ? customEventName
            : naming.renderEventName(domain: domainName, event: eventName);

    if (effectiveName.contains('{')) {
      final escapedEffectiveName =
          StringUtils.escapeDoubleQuoted(effectiveName);

      interpolatedName = escapedEffectiveName
          .replaceAllMapped(RegExp(r'\{([^}]+)\}'), (match) {
        final key = match.group(1)!;
        final found = parameters.where((p) => p.name == key).toList();
        if (found.isEmpty) return match.group(0)!;

        final camel = StringUtils.toCamelCase(found.first.name);
        return '\${$camel}';
      });
      // If no replacements were made (e.g. invalid placeholders), keep null to avoid noise?
      if (interpolatedName == escapedEffectiveName) {
        interpolatedName = null;
      }
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
      interpolatedName: interpolatedName,
    );
  }
}
