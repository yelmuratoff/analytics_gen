import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:yaml/yaml.dart';

import '../config/naming_strategy.dart';
import '../core/exceptions.dart';
import '../models/analytics_event.dart';
import '../util/event_naming.dart';

/// Validates analytics schema definitions.
final class SchemaValidator {
  /// Creates a new schema validator.
  const SchemaValidator(this.naming);

  /// The naming strategy to use.
  final NamingStrategy naming;

  /// Validates that a domain name adheres to the naming strategy.
  void validateDomainName(String domainName, String filePath) {
    if (!naming.isValidDomain(domainName)) {
      throw AnalyticsParseException(
        'Domain "$domainName" in $filePath violates the configured '
        'naming strategy. Update analytics_gen.naming.enforce_snake_case_domains '
        'or rename the domain.',
        filePath: filePath,
      );
    }
  }

  /// Ensures every resolved [AnalyticsEvent] identifier is unique across domains.
  void validateUniqueEventNames(
    Map<String, AnalyticsDomain> domains, {
    void Function(AnalyticsParseException)? onError,
  }) {
    final seen = <String, String>{};

    for (final entry in domains.entries) {
      final domainName = entry.key;
      for (final event in entry.value.events) {
        try {
          final actualIdentifier =
              EventNaming.resolveIdentifier(domainName, event, naming);
          final conflictDomain = seen[actualIdentifier];

          if (conflictDomain != null) {
            throw AnalyticsParseException(
              'Duplicate analytics event identifier "$actualIdentifier" found '
              'in domains "$conflictDomain" and "$domainName". '
              'Provide a custom `identifier` or update '
              '`analytics_gen.naming.identifier_template` to make identifiers unique.',
              filePath: event.sourcePath,
              lineNumber: event.lineNumber,
            );
          }

          seen[actualIdentifier] = domainName;
        } on AnalyticsParseException catch (e) {
          if (onError != null) {
            onError(e);
          } else {
            rethrow;
          }
        }
      }
    }
  }

  /// Validates that the root node of a YAML file is a map.
  void validateRootMap(YamlNode node, String filePath) {
    if (node is! YamlMap) {
      // If the file is empty or contains only comments, loadYamlNode might return a YamlScalar with null value
      if (node is YamlScalar && node.value == null) {
        return;
      }

      throw AnalyticsParseException(
        'Root of the YAML file must be a map.',
        filePath: filePath,
        span: node.span,
      );
    }
  }

  /// Validates that a domain definition is a map.
  void validateDomainMap(YamlNode node, String domainName, String filePath) {
    if (node is! YamlMap) {
      throw AnalyticsParseException(
        'Domain "$domainName" must be a map of events.',
        filePath: filePath,
        span: node.span,
      );
    }
  }

  /// Validates that parameters definition is a map.
  void validateParametersMap(
    YamlNode node,
    String domainName,
    String eventName,
    String filePath,
  ) {
    if (node is! YamlMap) {
      throw AnalyticsParseException(
        'Parameters for event "$domainName.$eventName" must be a map.',
        filePath: filePath,
        span: node.span,
      );
    }
  }

  /// Validates context file structure.
  void validateContextRoot(YamlNode node, String filePath) {
    if (node is! YamlMap) {
      throw AnalyticsParseException(
        'Context file must be a map.',
        filePath: filePath,
        span: node.span,
      );
    }

    final map = node;
    if (map.keys.length != 1) {
      throw AnalyticsParseException(
        'Context file must contain exactly one root key defining the context name.',
        filePath: filePath,
        span: map.span,
      );
    }
  }

  /// Validates context properties definition.
  void validateContextProperties(
    YamlNode node,
    String contextName,
    String filePath,
  ) {
    if (node is! YamlMap) {
      throw AnalyticsParseException(
        'The "$contextName" key must be a map of properties.',
        filePath: filePath,
        span: node.span,
      );
    }
  }
}
