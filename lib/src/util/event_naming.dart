import '../models/analytics_event.dart';
import 'string_utils.dart';

/// Shared naming helpers used by generators, parsers, and exports.
final class EventNaming {
  const EventNaming._();

  /// Resolves the actual analytics event name used when logging.
  static String resolveEventName(
    String domainName,
    AnalyticsEvent event,
  ) {
    return event.customEventName ?? '$domainName: ${event.name}';
  }

  /// Builds the generated logger method name from the domain/event names.
  static String buildLoggerMethodName(String domainName, String eventName) {
    final capitalizedDomain = StringUtils.capitalizePascal(domainName);
    final parts = eventName.split('_');
    final capitalizedEvent =
        parts.first + parts.skip(1).map(StringUtils.capitalizePascal).join();

    return 'log$capitalizedDomain${StringUtils.capitalizePascal(capitalizedEvent)}';
  }
}
