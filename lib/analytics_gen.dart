/// Analytics Gen - Type-safe analytics event tracking with code generation.
///
/// This package provides:
/// - Type-safe analytics event logging
/// - Code generation from YAML configuration
/// - Multiple analytics provider support
/// - Testing utilities
library;

// Core interfaces and base classes
export 'src/core/analytics_base.dart';
export 'src/core/analytics_interface.dart';

// Service implementations
export 'src/services/mock_analytics_service.dart';
export 'src/services/multi_provider_analytics.dart';

// Configuration
export 'src/config/analytics_config.dart';

// Models (useful for advanced usage)
export 'src/models/analytics_event.dart';
