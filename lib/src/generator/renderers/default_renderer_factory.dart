import '../../config/analytics_config.dart';
import 'event_renderer.dart';
import 'renderer_factory.dart';

/// Default implementation of [RendererFactory].
class DefaultRendererFactory implements RendererFactory {
  /// Creates a new default renderer factory.
  const DefaultRendererFactory();

  @override
  EventRenderer createEventRenderer(AnalyticsConfig config) {
    return EventRenderer(config);
  }
}
