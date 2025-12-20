import '../../config/analytics_config.dart';
import 'event_renderer.dart';

/// Factory for creating renderers.
abstract interface class RendererFactory {
  /// Creates an event renderer.
  EventRenderer createEventRenderer(AnalyticsConfig config);
}
