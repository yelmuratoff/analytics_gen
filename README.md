<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/analytics_gen.png?raw=true" width="400">

  <p><strong>Type-safe analytics event tracking with code generation from YAML configuration.</strong></p>

  <p>
    <a href="https://pub.dev/packages/analytics_gen">
      <img src="https://img.shields.io/pub/v/analytics_gen?include_prereleases&style=for-the-badge&logo=flutter&labelColor=000000&color=DF4926" alt="pub version">
    </a>
    <a href="https://opensource.org/licenses/Apache-2.0">
      <img src="https://img.shields.io/github/license/yelmuratoff/analytics_gen?style=for-the-badge&logo=apache&labelColor=000000&color=DF4926" alt="License">
    </a>
    <a href="https://github.com/yelmuratoff/analytics_gen">
      <img src="https://img.shields.io/github/stars/yelmuratoff/analytics_gen?style=for-the-badge&logo=github&labelColor=000000&color=DF4926" alt="GitHub stars">
    </a>
  </p>

  <p>
    <a href="https://pub.dev/packages/analytics_gen/score">
      <img src="https://img.shields.io/pub/likes/analytics_gen?style=for-the-badge&logo=flutter&labelColor=000000&color=DF4926" alt="Pub likes">
    </a>
    <a href="https://pub.dev/packages/analytics_gen/score">
      <img src="https://img.shields.io/pub/points/analytics_gen?style=for-the-badge&logo=flutter&labelColor=000000&color=DF4926" alt="Pub points">
    </a>
    <a href="https://pub.dev/packages/analytics_gen/downloads">
      <img src="https://img.shields.io/pub/dm/analytics_gen?style=for-the-badge&logo=flutter&labelColor=000000&color=DF4926" alt="Pub downloads">
    </a>
  </p>
</div>

## Features

- **Type Safety**: Compile-time checking for all events and parameters
- **Code Generation**: Strongly-typed Dart methods from YAML definitions
- **Auto-generated Analytics Class**: No manual setup required
- **Organized Structure**: Each domain in separate file for better readability
- **Multi-Provider**: Send events to multiple analytics platforms simultaneously
- **Export Formats**: CSV, JSON, SQL, and SQLite database
- **Testing Support**: Built-in `MockAnalyticsService` for unit tests
- **Watch Mode**: Auto-regenerate on YAML file changes

## Quick Start

### 1. Install

```yaml
dev_dependencies:
  analytics_gen: ^0.1.1
```

### 2. Define Events

Create `events/auth.yaml`:

```yaml
auth:
  login:
    description: User logs in
    parameters:
      method:
        type: string
        description: Login method (email, google, apple)
  
  logout:
    description: User logs out
    parameters: {}
```

### 3. Generate Code

```bash
dart run analytics_gen:generate --docs --exports
```

This automatically generates a clean, organized structure:

```
lib/src/analytics/generated/
├── analytics.dart              # Auto-generated singleton
├── generated_events.dart       # Barrel file (exports)
└── events/
    ├── auth_events.dart       # Auth domain events
    ├── screen_events.dart     # Screen domain events
    └── purchase_events.dart   # Purchase domain events
```

### 4. Use It

```dart
import 'package:analytics_gen/analytics_gen.dart';
import 'src/analytics/generated/analytics.dart';

void main() {
  // Initialize once
  Analytics.initialize(YourAnalyticsService());
  
  // Use anywhere
  Analytics.instance.logAuthLogin(method: 'email');
  Analytics.instance.logAuthLogout();
}
```

## Why This Structure?

- **Readable**: Each domain in separate file - easy to navigate
- **Maintainable**: Changes to one domain don't affect others
- **Scalable**: Add domains without making files huge
- **Clean Imports**: Barrel file provides single import point

## Configuration

Create `analytics_gen.yaml` in your project root (optional):

```yaml
analytics_gen:
  events_path: events                      # YAML event files location
  output_path: src/analytics/generated     # Generated code output
  docs_path: docs/analytics_events.md      # Documentation output
  exports_path: assets/generated           # Exports output
  generate_docs: true
  generate_csv: true
  generate_json: true
  generate_sql: true
```

## YAML Schema

### Basic Event

```yaml
domain_name:
  event_name:
    description: Event description
    parameters:
      param1: string
      param2: int
```

### Nullable Parameters

```yaml
auth:
  signup:
    description: User signs up
    parameters:
      referral_code: string?  # Optional parameter
```

### Parameters with Descriptions

```yaml
purchase:
  completed:
    description: Purchase completed
    parameters:
      product_id:
        type: string
        description: ID of purchased product
      price:
        type: double
        description: Purchase price
```

### Custom Event Names

```yaml
screen:
  view:
    description: Screen viewed
    event_name: "Screen: View"  # Custom name for legacy systems
    parameters:
      screen_name: string
```

### Supported Types

- `int`, `string`, `bool`, `double`, `float`
- `map` (Map<String, dynamic>)
- `list` (List<dynamic>)
- Add `?` for nullable: `string?`, `int?`

## CLI Commands

```bash
# Generate code only
dart run analytics_gen:generate

# Generate code + documentation
dart run analytics_gen:generate --docs

# Generate everything
dart run analytics_gen:generate --docs --exports

# Watch mode (auto-regenerate on changes)
dart run analytics_gen:generate --watch
```

## Generated Files

### Code Structure
```
lib/src/analytics/generated/
├── analytics.dart              # Singleton with all mixins
├── generated_events.dart       # Barrel file
└── events/
    ├── auth_events.dart       # AnalyticsAuth mixin
    ├── screen_events.dart     # AnalyticsScreen mixin
    └── purchase_events.dart   # AnalyticsPurchase mixin
```

### Documentation & Exports (Optional)
- **Docs**: `docs/analytics_events.md`
- **CSV**: `assets/generated/analytics_events.csv`
- **JSON**: `assets/generated/analytics_events.json`
- **SQL**: `assets/generated/create_database.sql`
- **SQLite**: `assets/generated/analytics_events.db`

## Analytics Providers

### Mock Service (Testing)

```dart
final mockService = MockAnalyticsService(verbose: true);
Analytics.initialize(mockService);

// Verify in tests
expect(mockService.totalEvents, equals(1));
expect(mockService.getEventsByName('login'), hasLength(1));
```

### Multi-Provider

```dart
final multiProvider = MultiProviderAnalytics([
  FirebaseAnalyticsService(firebase),
  AmplitudeService(amplitude),
]);
Analytics.initialize(multiProvider);
```

### Custom Provider

```dart
class FirebaseAnalyticsService implements IAnalytics {
  final FirebaseAnalytics _firebase;
  
  FirebaseAnalyticsService(this._firebase);
  
  @override
  void logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) {
    _firebase.logEvent(name: name, parameters: parameters);
  }
}
```

## Testing

```dart
void main() {
  group('Analytics', () {
    late MockAnalyticsService analytics;
    
    setUp(() {
      analytics = MockAnalyticsService();
      Analytics.initialize(analytics);
    });
    
    test('logs login event', () {
      Analytics.instance.logAuthLogin(method: 'email');
      
      expect(analytics.totalEvents, equals(1));
      final event = analytics.events.first;
      expect(event['name'], equals('auth: login'));
      expect(event['parameters'], containsPair('method', 'email'));
    });
  });
}
```

## Example

See [`example/`](example/) for a complete working project.

Run the example:

```bash
cd example
dart pub get
dart run analytics_gen:generate --docs --exports
dart run lib/main.dart
```

## License

Apache License - see [LICENSE](LICENSE) file.
