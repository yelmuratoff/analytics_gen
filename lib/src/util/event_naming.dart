import '../config/naming_strategy.dart';
import '../models/analytics_event.dart';
import 'string_utils.dart';

/// Shared naming helpers used by generators, parsers, and exports.
final class EventNaming {
  /// Resolves the actual analytics event name used when logging.
  static String resolveEventName(
    String domainName,
    AnalyticsEvent event,
    NamingStrategy naming,
  ) {
    final custom = event.customEventName;
    if (custom != null && custom.isNotEmpty) return custom;
    return naming.renderEventName(domain: domainName, event: event.name);
  }

  /// Resolves the canonical identifier for an analytics event.
  static String resolveIdentifier(
    String domainName,
    AnalyticsEvent event,
    NamingStrategy naming,
  ) {
    final identifier = event.identifier;
    if (identifier != null && identifier.isNotEmpty) {
      return identifier;
    }
    final custom = event.customEventName;
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    return naming.renderIdentifier(domain: domainName, event: event.name);
  }

  /// Builds the generated logger method name from the domain/event names.
  static String buildLoggerMethodName(String domainName, String eventName) {
    final capitalizedDomain = StringUtils.capitalizePascal(domainName);
    final parts = eventName.split('_');
    final capitalizedEvent =
        parts.first + parts.skip(1).map(StringUtils.capitalizePascal).join();

    return 'log$capitalizedDomain${StringUtils.capitalizePascal(capitalizedEvent)}';
  }

  /// Builds a logger method name from a replacement reference like `domain.event`.
  static String? buildLoggerMethodNameFromReplacement(String replacement) {
    final segments = replacement.split('.');
    if (segments.length < 2) return null;

    final domain = segments.first.trim();
    final eventName = segments.sublist(1).join('.');

    if (domain.isEmpty || eventName.isEmpty) return null;

    return buildLoggerMethodName(domain, eventName);
  }
}
