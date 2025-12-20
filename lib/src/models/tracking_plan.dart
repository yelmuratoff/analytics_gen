import '../models/analytics_domain.dart';
import '../models/analytics_parameter.dart';

/// Represents a fully parsed and validated tracking plan.
final class TrackingPlan {
  /// Creates a new tracking plan.
  const TrackingPlan({
    required this.domains,
    required this.contexts,
  });

  /// All analytics domains indexed by name.
  final Map<String, AnalyticsDomain> domains;

  /// Global context properties indexed by name.
  final Map<String, List<AnalyticsParameter>> contexts;

  /// The total number of events across all domains.
  int get totalEvents => domains.values.fold(0, (sum, d) => sum + d.eventCount);

  /// The total number of unique parameters across all events and contexts.
  int get totalParameters =>
      domains.values.fold(0, (sum, d) => sum + d.parameterCount);
}
