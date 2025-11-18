import 'package:analytics_gen/analytics_gen.dart';

import 'analytics_event_log.dart';

/// Wraps an [IAnalytics] delegate and surfaces every logged event for observers.
class ObservableAnalytics implements IAnalytics {
  ObservableAnalytics({
    required IAnalytics delegate,
    required void Function(LoggedAnalyticsEvent event) onRecord,
  }) : _delegate = delegate,
       _onRecord = onRecord;

  final IAnalytics _delegate;
  final void Function(LoggedAnalyticsEvent event) _onRecord;

  @override
  void logEvent({required String name, AnalyticsParams? parameters}) {
    _delegate.logEvent(name: name, parameters: parameters);

    _onRecord(
      LoggedAnalyticsEvent(
        name: name,
        parameters: Map<String, Object?>.unmodifiable(
          parameters ?? const <String, Object?>{},
        ),
        timestamp: DateTime.now(),
      ),
    );
  }
}
