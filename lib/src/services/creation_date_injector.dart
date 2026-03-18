import '../models/analytics_domain.dart';
import '../models/tracking_plan.dart';

/// Injects `tracking_creation_date` from the ledger into each event's meta.
final class CreationDateInjector {
  /// Creates a new creation date injector.
  const CreationDateInjector();

  static const String _key = 'tracking_creation_date';

  /// Returns a new [TrackingPlan] with creation dates injected into event meta.
  TrackingPlan inject(TrackingPlan plan, Map<String, String> ledger) {
    final updatedDomains = <String, AnalyticsDomain>{};

    for (final entry in plan.domains.entries) {
      final domainName = entry.key;
      final domain = entry.value;

      final updatedEvents = domain.events.map((event) {
        final ledgerKey = '$domainName.${event.name}';
        final date = ledger[ledgerKey];
        if (date == null) return event;

        return event.copyWith(
          meta: {...event.meta, _key: date},
        );
      }).toList();

      updatedDomains[domainName] = domain.copyWith(events: updatedEvents);
    }

    return TrackingPlan(
      domains: updatedDomains,
      contexts: plan.contexts,
    );
  }
}
