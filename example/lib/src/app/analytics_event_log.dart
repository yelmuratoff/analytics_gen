class LoggedAnalyticsEvent {
  const LoggedAnalyticsEvent({
    required this.name,
    required this.parameters,
    required this.timestamp,
  });

  final String name;
  final Map<String, Object?> parameters;
  final DateTime timestamp;
}
