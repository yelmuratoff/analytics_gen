# Analytics Gen

A Dart package for structured analytics event tracking with code and documentation generation from YAML configuration.

## Features

- **Modular YAML schema**: Define events in multiple files under `events/`, one per domain.
- **Code generation**: Strongly-typed analytics methods generated from YAML.
- **Nullable parameters**: Use `?` in YAML types for optional parameters.
- **Custom event names**: Use the optional `event_name` field for legacy or custom naming.
- **Naming conventions**: Method arguments are camelCase; logged parameters are snake_case.
- **Documentation generation**: Generates Markdown docs for all events and parameters.
- **Data export capabilities**: Export analytics events to CSV, JSON, and SQL formats.
- **Excel integration**: Generate Excel-compatible CSV files for business analysis.
- **Database support**: Complete SQLite schema generation with data population.
- **Supports multiple analytics providers** (Amplitude, Firebase, etc.)

## Getting Started

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  analytics_gen: ^0.0.0-dev01

dev_dependencies:
  build_runner: ^2.4.0
```

### Event Configuration

1. **Create event YAML files in the `events/` folder** (one file per domain):

Example: `events/menu.yaml`
```yaml
menu:
  chapter:
    description: User taps chapter in menu
    parameters:
      id: int
      link: string
```

Example: `events/auth.yaml`
```yaml
auth:
  google_login:
    description: Logs in via Google
    parameters: {}
```

- **Supported types**: `int`, `string`, `bool`, `double`, `map`, `list`
- **Nullable parameters**: Add `?` (e.g. `user_id: int?`)
- **Custom event name**: Add `event_name` (optional) for legacy compatibility:
  ```yaml
  block_info_icon:
    description: User taps block info icon
    event_name: "AI Movement: Block info icon"
    parameters:
      block_type: string
  ```

> All YAML files in `events/` are merged automatically. Fallback to `analytics_events.yaml` in root is supported for legacy.
> 
> - **No duplication**: Each event must be defined in only one domain file. For example, the screen view event is defined only in `screen.yaml` (not in `navigation.yaml`).

### Code & Documentation Generation

You can generate analytics code and documentation in several ways:

#### 1. Using build_runner

```bash
dart run build_runner build --delete-conflicting-outputs
```

#### 2. Using the analytics_gen script

```bash
dart run analytics_gen:generate
```

#### 3. Using the locally activated command

```bash
analytics_gen generate
```

**Additional options:**
```bash
# Watch mode (auto-regenerate on file changes)
dart run analytics_gen:generate --watch

# Generate code and documentation at the same time
dart run analytics_gen:generate --with-docs

# Generate documentation only
dart run analytics_gen:docs

# Generate database export files (CSV, JSON, SQL)
dart tool/generate_database.dart
```

### Usage

```dart
import 'package:amplitude_flutter/amplitude.dart';
import 'package:analytics_gen/analytics_gen.dart';

void initAnalytics() {
  final amplitude = Amplitude.getInstance('YOUR_API_KEY');
  Analytics.initialize(AmplitudeService(amplitude));
}

// Track events with type safety
void trackEvents() {
  // Event with parameters (camelCase arguments)
  Analytics.instance.logMenuChapter(
    id: 123,
    link: '/home',
  );

  // Event without parameters
  Analytics.instance.logAuthGoogleLogin();
}
```

- **Arguments**: camelCase in Dart methods, e.g. `userId`
- **Logged parameters**: snake_case in analytics, e.g. `user_id`
- **Nullable/optional**: Omit or pass `null` for nullable parameters

## Adding New Events

1. Add a new YAML file or event to an existing file in `events/`:

```yaml
profile:
  view:
    description: User views profile page
    parameters:
      user_id: int
      from_screen: string
  edit:
    description: User edits profile
    parameters:
      fields_changed: list
```

2. Run code generation (see above).

3. If needed, add the new mixin to your `Analytics` class:

```dart
final class Analytics extends AnalyticsBase with
    AnalyticsMenu,
    AnalyticsAuth,
    AnalyticsProfile // Add new mixin here
{
  // ... existing code
}
```

## Event YAML Schema

```yaml
domain_name:
  event_name:
    description: Event description
    event_name: "Custom event name" # (optional)
    parameters:
      param1: type
      param2: type?
```

- **Nullable**: Add `?` to type for optional/nullable parameters.
- **event_name**: If present, used as the event name in analytics (for legacy compatibility).

## Documentation

- Run `dart run analytics_gen:docs` to generate Markdown documentation (`analytics_docs.md`) for all events and parameters.
- See `/events/README.md` for event file structure.

## Custom Analytics Services

Implement the `IAnalytics` interface to support any analytics provider:

```dart
class FirebaseAnalyticsService implements IAnalytics {
  final FirebaseAnalytics _firebase;
  FirebaseAnalyticsService(this._firebase);

  @override
  void logEvent({
    required String name,
    String? domain,
    Map<String, dynamic> parameters = const {},
  }) {
    _firebase.logEvent(name: name, parameters: parameters);
  }
}
```

## Multiple Analytics Providers

Send events to multiple providers:

```dart
final multiProvider = MultiProviderAnalytics([
  AmplitudeService(amplitude),
  FirebaseAnalyticsService(firebase),
]);
Analytics.initialize(multiProvider);
```

## Testing

- Use `MockAnalyticsService` for tests and local development.
- See `test/` for usage examples.

## Data Export & Database Generation

The package includes powerful data export capabilities for analytics events, supporting multiple formats for different use cases:

### Available Export Formats

- **CSV**: Excel-compatible format with filtering and sorting capabilities
- **JSON**: Web-friendly format for APIs and web tools (pretty and minified versions)
- **SQL**: Complete database schema with SQLite scripts for data persistence

### Generate Database Files

```bash
# Generate all database files
dart tool/generate_database.dart
```

This command creates the following files in `assets/generated/`:

- `analytics_events.csv` - Excel-compatible CSV file with all events and parameters
- `analytics_events.json` - Pretty-formatted JSON for web tools and APIs
- `analytics_events.min.json` - Compressed JSON for production use
- `create_database.sql` - Complete SQLite database schema with data inserts

### CSV Export Features

The CSV export provides:

- **Excel compatibility**: Opens directly in Excel, Google Sheets, or any spreadsheet application
- **Filterable columns**: Domain, Action, Event Name, Description, Parameters
- **Readable parameters**: Parameters formatted as `param_name (type)` or `param_name (type): description`
- **Proper escaping**: Handles commas, quotes, and newlines correctly
- **Parameter descriptions**: Includes detailed parameter descriptions when available

Example CSV structure:
```csv
Domain,Action,Event Name,Description,Parameters
auth,phone_login,Auth: Phone,When user logs in via phone,user_exists (bool?): Whether the user exists or not
quest,quiz,Quest: quiz,When user do some actions on quiz,event_id (int); game_id (int); status (string?); action (String)
```

### JSON Export Features

The JSON export includes:

- **Metadata**: Generation timestamp, totals, and version information
- **Hierarchical structure**: Organized by domains and events
- **Parameter details**: Type information, descriptions, and nullable flags
- **Statistics**: Event counts and parameter counts per domain

### SQL Database Features

The SQL export provides:

- **Complete schema**: Tables for domains, events, and parameters with proper relationships
- **Data inserts**: All analytics events pre-populated in the database
- **Indexes**: Optimized for common queries and lookups
- **Views**: Pre-built views for common analytics queries
- **Foreign keys**: Proper referential integrity between tables

### Use Cases

- **Business Analysis**: Use CSV files in Excel for filtering, sorting, and creating reports
- **Technical Documentation**: Use JSON for automated documentation systems
- **Data Warehouse**: Use SQL scripts to populate analytics databases
- **API Integration**: Use minified JSON for web services and APIs
- **Stakeholder Reports**: Share Excel-friendly CSV files with non-technical team members

### File Locations

All generated files are placed in:

```
assets/generated/
├── analytics_events.csv      # Excel-compatible CSV
├── analytics_events.json     # Pretty JSON
├── analytics_events.min.json # Minified JSON
└── create_database.sql       # SQLite schema + data
```

---

## Additional Resources

For more information, refer to:

- **Generated documentation**: `analytics_docs.md` - Complete event documentation
- **Export files**: `assets/generated/` - CSV, JSON, and SQL data exports  
- **Event structure**: `/events/README.md` - YAML file organization guide
- **Test examples**: `test/` - Usage examples and testing patterns

## Support

This package provides comprehensive analytics event management with:
- ✅ **Type-safe code generation** from YAML configuration
- ✅ **Multiple export formats** for different use cases
- ✅ **Excel-compatible data** for business analysis
- ✅ **Database integration** with complete SQL schemas
- ✅ **Multi-provider support** for various analytics services
