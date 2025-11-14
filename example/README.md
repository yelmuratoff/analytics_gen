# Analytics Gen Example

This example demonstrates how to define a YAML tracking plan and use the generated, type‑safe Dart API from the `analytics_gen` package.

## Project Structure

```
example/
├── analytics_gen.yaml      # Configuration file
├── events/                 # YAML event definitions
│   ├── auth.yaml          # Authentication events
│   ├── screen.yaml        # Screen navigation events
│   └── purchase.yaml      # Purchase events
├── lib/
│   ├── src/
│   │   └── analytics/
│   │       └── generated/               # Auto-generated code
│   │           ├── analytics.dart       # Analytics singleton (generated!)
│   │           └── generated_events.dart # Event mixins (generated!)
│   └── main.dart          # Example usage
└── docs/                   # Generated documentation
```

## Quick Start

### 1. Install Dependencies

```bash
cd example
dart pub get
```

### 2. Generate Analytics Code

```bash
# Generate code only
dart run analytics_gen:generate

# Generate code + documentation
dart run analytics_gen:generate --docs

# Generate everything (code + docs + exports)
dart run analytics_gen:generate --docs --exports

# Watch mode (auto-regenerate on changes)
dart run analytics_gen:generate --watch
```

### 3. Run the Example

```bash
dart run lib/main.dart
```

## What Gets Generated?

After running the generator, you'll have:

### Generated Code
- `lib/src/analytics/generated/analytics.dart` - **Analytics singleton with all mixins (auto-generated)**
- `lib/src/analytics/generated/generated_events.dart` - Type-safe event mixins

### Documentation (if `--docs`)
- `docs/analytics_events.md` - Complete Markdown documentation

### Exports (if `--exports`)
- `assets/generated/analytics_events.csv` - Excel-compatible CSV
- `assets/generated/analytics_events.json` - Pretty JSON
- `assets/generated/analytics_events.min.json` - Minified JSON
- `assets/generated/create_database.sql` - SQLite schema
- `assets/generated/analytics_events.db` - SQLite database file

## Configuration

The `analytics_gen.yaml` file controls code generation:

```yaml
analytics_gen:
  # Where to find YAML event files
  events_path: events
  
  # Where to output generated Dart code
  output_path: src/analytics/generated
  
  # Where to output documentation
  docs_path: docs/analytics_events.md
  
  # Where to output export files (CSV, JSON, SQL)
  exports_path: assets/generated
  
  # What to generate
  generate_docs: true
  generate_csv: true
  generate_json: true
  generate_sql: true
```

## Defining Events

Create YAML files in the `events/` directory. Each file represents a domain:

### events/auth.yaml

```yaml
auth:
  login:
    description: User logs in to the application
    parameters:
      method:
        type: string
        description: Login method (email, google, apple)
      
  logout:
    description: User logs out
    parameters: {}
```

### Supported Parameter Types

- `int` - Integer values
- `string` - String values
- `bool` - Boolean values
- `double` - Floating point values
- `map` - Map<String, dynamic>
- `list` - List<dynamic>

Add `?` for nullable parameters: `string?`, `int?`, etc.

## Using Analytics

The Analytics class is **automatically generated** with all your domain mixins!

```dart
import 'package:analytics_gen/analytics_gen.dart';
import 'src/analytics/generated/analytics.dart';  // Auto-generated!

void main() {
  // Initialize once at app startup
  Analytics.initialize(YourAnalyticsService());
  
  // Use anywhere in your app
  Analytics.instance.logAuthLogin(method: 'email');
  Analytics.instance.logAuthLogout();
  Analytics.instance.logScreenView(screenName: 'home');
}
```

## Testing with MockAnalyticsService

```dart
import 'package:analytics_gen/analytics_gen.dart';
import 'src/analytics/generated/analytics.dart';

void main() {
  // Initialize with mock for testing/development
  final mockService = MockAnalyticsService(verbose: true);
  Analytics.initialize(mockService);
  
  // Log events
  Analytics.instance.logAuthLogin(method: 'email');
  
  // Verify in tests
  print('Total events: ${mockService.totalEvents}');
  print("Login events: ${mockService.getEventsByName('auth: login').length}");
}
```

## Multiple Analytics Providers

```dart
import 'package:analytics_gen/analytics_gen.dart';
import 'src/analytics/generated/analytics.dart';

void main() {
  // Send to multiple platforms
  final multiProvider = MultiProviderAnalytics([
    FirebaseAnalyticsService(firebaseAnalytics),
    AmplitudeService(amplitude),
  ]);
  
  Analytics.initialize(multiProvider);
}
```

## Custom Analytics Provider

Implement the `IAnalytics` interface:

```dart
class FirebaseAnalyticsService implements IAnalytics {
  final FirebaseAnalytics _firebase;
  
  FirebaseAnalyticsService(this._firebase);
  
  @override
  void logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) {
    _firebase.logEvent(
      name: name,
      parameters: parameters,
    );
  }
}
```

## Key Points

1. **No Manual Class Creation**: The Analytics singleton is automatically generated with all your domain mixins
2. **One domain per file**: Keep related events together (auth, screen, purchase)
3. **Descriptive names**: Use clear event and parameter names
4. **Add descriptions**: They appear in generated docs and exports
5. **Watch mode**: Use `--watch` during development for auto-regeneration
6. **Version control**: Commit YAML files, optionally ignore generated code

## Workflow

1. **Define events** in YAML files (`events/auth.yaml`, etc.)
2. **Run generator**: `dart run analytics_gen:generate`
3. **Import generated class**: `import 'src/analytics/generated/analytics.dart';`
4. **Initialize**: `Analytics.initialize(yourService);`
5. **Use**: `Analytics.instance.logAuthLogin(...);`

## Next Steps

- Explore generated documentation in `docs/analytics_events.md`
- Check out generated exports in `assets/generated/`
- Add your own event domains
- Integrate with your analytics provider
- Run tests with MockAnalyticsService
