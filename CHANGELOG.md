# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2024-01-15

### Added

- **Organized file structure**: Each domain generates separate file in `events/` directory
- **Automatic Analytics class generation**: No manual setup required
- **Barrel file**: Clean imports through `generated_events.dart`
- Type-safe analytics event tracking with code generation from YAML
- `IAnalytics` interface for implementing custom analytics providers
- `AnalyticsBase` class for generated mixins
- `MockAnalyticsService` for testing and development
- `MultiProviderAnalytics` for sending events to multiple providers
- CLI tool with watch mode, docs, and exports options
- Configuration support via `analytics_gen.yaml`
- YAML parser with support for multiple event files per project
- Documentation generator producing Markdown files
- Separate export generators: CSV, JSON, SQL, and SQLite
- Support for nullable parameters using `?` suffix
- Support for custom event names via `event_name` field
- Parameter descriptions in YAML for better documentation
- Watch mode for auto-regeneration during development
- Comprehensive example project
- Full test suite (20 tests passing)

### Features

#### Clean File Structure
```
lib/src/analytics/generated/
├── analytics.dart              # Auto-generated singleton
├── generated_events.dart       # Barrel file
└── events/
    ├── auth_events.dart       # Auth domain
    ├── screen_events.dart     # Screen domain
    └── purchase_events.dart   # Purchase domain
```

Benefits:
- **Readable**: Easy to navigate, one domain per file
- **Maintainable**: Changes isolated to specific files
- **Scalable**: No huge monolithic files
- **Clean**: Barrel file for simple imports

#### Automatic Code Generation
- **Analytics class**: Auto-generated singleton with all domain mixins
- **Type-safe mixins**: Strongly-typed methods per domain
- **Naming conventions**: camelCase in Dart, snake_case in analytics
- **Compile-time safety**: Catch errors before runtime

#### Separated Export Generators
- **CSV Generator**: Excel-compatible exports
- **JSON Generator**: Pretty and minified formats
- **SQL Generator**: Complete database schema
- **SQLite Generator**: Actual .db file (if sqlite3 available)

Each generator in separate file for:
- Single responsibility
- Easy testing
- Simple extension

#### Supported Types
- `int`, `string`, `bool`, `double`/`float`
- `map` (Map<String, dynamic>)
- `list` (List<dynamic>)
- All types support nullable variants with `?`

#### Testing
- `MockAnalyticsService` records all events
- Query methods: `getEventsByName()`, `getEventCount()`
- Optional verbose mode for debugging
- Full test coverage

#### Multi-Provider Support
- Forward to multiple platforms simultaneously
- Error handling: continues if one provider fails
- Dynamic provider management

### Example Usage

```dart
// 1. Define events in events/auth.yaml
auth:
  login:
    description: User logs in
    parameters:
      method: string

// 2. Generate code (creates organized structure!)
dart run analytics_gen:generate

// 3. Import and use
import 'src/analytics/generated/analytics.dart';

Analytics.initialize(YourAnalyticsService());
Analytics.instance.logAuthLogin(method: 'email');
```

### Technical Details

- Minimum Dart SDK: ^3.7.2
- Dependencies: yaml ^3.1.3, path ^1.9.1, args ^2.4.2
- No external dependencies for SQLite (uses system sqlite3 command)
- Architecture: Clean separation of concerns
- Configuration: Optional YAML config file

[0.1.0]: https://github.com/yourusername/analytics_gen/releases/tag/v0.1.0
