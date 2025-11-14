<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/analytics_gen.png?raw=true" width="400">

  <p><strong>Type‑safe analytics events from a single YAML source of truth.</strong></p>

  <p>
    <a href="https://pub.dev/packages/analytics_gen">
      <img src="https://img.shields.io/pub/v/analytics_gen?include_prereleases&style=for-the-badge&logo=flutter&labelColor=000000&color=DF4926" alt="pub version">
    </a>
    <a href="https://opensource.org/licenses/Apache-2.0">
      <img src="https://img.shields.io/badge/license-apache 2.0-blue?style=for-the-badge&logo=apache&labelColor=000000&color=DF4926" alt="License">
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
    <!-- <a href="https://pub.dev/packages/analytics_gen/downloads">
      <img src="https://img.shields.io/pub/dm/analytics_gen?style=for-the-badge&logo=flutter&labelColor=000000&color=DF4926" alt="Pub downloads">
    </a> -->
  </p>
</div>

## Overview

`analytics_gen` keeps your tracking plan, generated code, and analytics providers in sync.

You describe events once in YAML; the package generates:

- A type‑safe Dart API for all events and parameters
- A single `Analytics` entrypoint with domain‑specific mixins
- Optional documentation and export files (CSV/JSON/SQL/SQLite)

This removes hand‑written string keys, reduces tracking drift between platforms, and makes analytics changes easy to review and refactor.

## Key Features

- **Type‑safe events**: Compile‑time checking of event names and parameter types
- **Code generation from YAML**: Strongly‑typed Dart methods derived from simple YAML definitions
- **Clean structure by domain**: Each domain (`auth`, `screen`, `purchase`, etc.) lives in its own generated file
- **Multi‑provider support**: Fan out a single event call to multiple analytics backends
- **Export formats**: Generate CSV, JSON, SQL, and SQLite representations of your tracking plan
- **Watch mode**: Optional file watcher to regenerate when YAML changes

## When to Use (and When Not)

Use `analytics_gen` when:

- You have more than a handful of events and want a single, reviewable tracking plan
- Multiple teams (product, data, engineering) need a shared source of truth
- You send the same events to multiple analytics providers
- You want compile‑time guarantees instead of stringly‑typed `logEvent('some_name')` calls

You probably do not need `analytics_gen` when:

- You have a very small app with a few one‑off events
- Your analytics plan changes rarely and is maintained manually
- You prefer provider‑specific SDK features over a unified interface

## Quick Start

### 1. Install

```yaml
dev_dependencies:
  analytics_gen: ^0.1.3
```

### 2. Define Events (YAML Tracking Plan)

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

This generates a clean, organized structure:

```
lib/src/analytics/generated/
├── analytics.dart              # Auto-generated singleton
├── generated_events.dart       # Barrel file (exports)
└── events/
    ├── auth_events.dart       # Auth domain events
    ├── screen_events.dart     # Screen domain events
    └── purchase_events.dart   # Purchase domain events
```

### 4. Use It in Your App

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

- **Readable**: Each domain lives in a separate file — easy to navigate and review
- **Maintainable**: Changes to one domain do not affect others
- **Scalable**: Adding new domains does not grow a single “god file”
- **Clean imports**: A barrel file provides a single import point for all events

## Configuration

Create `analytics_gen.yaml` in your project root (optional, with sensible defaults if omitted):

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

### Custom Event Names (for Legacy / External Systems)

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

### Domain Naming

- Domain keys (top-level YAML keys) must be snake_case, using only lowercase letters, digits, and underscores (e.g. `auth`, `screen_navigation`).
- This keeps generated file and class names stable and filesystem‑safe.

## CLI Commands

```bash
# Generate code only (default)
dart run analytics_gen:generate

# Generate code + documentation
dart run analytics_gen:generate --docs

# Generate everything
dart run analytics_gen:generate --docs --exports

# Docs only
dart run analytics_gen:generate --docs --no-code

# Exports only
dart run analytics_gen:generate --exports --no-code

# Watch mode (auto-regenerate on changes)
dart run analytics_gen:generate --watch

# Quiet mode (no generator logs, only summary)
dart run analytics_gen:generate --no-verbose
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
expect(
  mockService.getEventsByName('login'),
  hasLength(1),
);
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
    AnalyticsParams? parameters,
  }) {
    _firebase.logEvent(name: name, parameters: parameters);
  }
}
```

`AnalyticsParams` is a typedef for `Map<String, Object?>`. In practice:

- Keys are always `String` in snake_case.
- Values should be JSON-serializable (String, num, bool, null, List, Map) or simple objects supported by your analytics SDK.

### Sync vs Async logging

- The `IAnalytics.logEvent` API is synchronous for ergonomics in UI and business code.
- Your implementation may perform asynchronous work internally (e.g. calling an async SDK), but the generated methods themselves do not return a `Future`.
- If you need strict delivery guarantees, handle retries and error reporting inside your `IAnalytics` implementation.

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

Licensed under the Apache License, Version 2.0. See [`LICENSE`](LICENSE) for details.

## FAQ

**Why YAML instead of defining events directly in Dart?**  
YAML keeps the tracking plan tooling‑agnostic: product and analytics teams can read and edit it, and you can export the same source of truth to code, docs, and data formats.

**Can I migrate existing events?**  
Yes. Start by describing your current events in YAML, generate Dart code, then gradually replace existing manual `logEvent` calls with the generated methods.

**Does this lock me into a single analytics provider?**  
No. You implement `IAnalytics` adapters for each provider and can use `MultiProviderAnalytics` to send the same event to several backends.

**Is this safe to commit to source control?**  
Yes. The YAML definitions and generated code are designed to be code‑review friendly and should live in your repo alongside application code.
