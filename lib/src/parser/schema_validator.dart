import '../config/naming_strategy.dart';
import '../core/exceptions.dart';
import '../models/analytics_event.dart';
import '../util/event_naming.dart';

/// Validates analytics schema definitions.
final class SchemaValidator {
  final NamingStrategy naming;

  const SchemaValidator(this.naming);

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
              filePath: null,
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
}
