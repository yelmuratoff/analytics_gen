# Troubleshooting Guide

Common issues and solutions when using `analytics_gen`.

## CLI Errors

### `AnalyticsParseException: Domain name "..." is invalid`
**Cause**: The top-level key in your YAML file does not match the configured naming strategy (default: snake_case).
**Fix**: Rename the key in YAML or checking `analytics_gen.yaml`:
```yaml
# Correct (snake_case)
user_profile:
  events: ...
```

### `AnalyticsParseException: Parameter "..." is defined in event "..." but requires central definition`
**Cause**: `rules: enforce_centrally_defined_parameters: true` is enabled.
**Fix**: Move the parameter definition to a file listed in `shared_parameters` or disable the rule.

### `Exit code 255` or `Stack Overflow`
**Cause**: Extremely deep YAML nesting, malformed YAML, or very large single files.
**Fix**: Split domains into multiple files and keep structures shallow (domains → events → parameters). Re-run with `--verbose` to capture the failing file/line.

## Generated Code Issues

### `The method 'log...' isn't defined for the type 'Analytics'`
**Cause**:
1. You haven't run the generator: `dart run analytics_gen:generate`
2. You're importing the wrong `Analytics` type (the package exports runtime helpers, not your app's generated `Analytics` class).
3. You generated to a different output directory than you are importing.
**Fix**:
1. Run generation and ensure it writes code (`--no-code` disables code output):
```bash
dart run analytics_gen:generate --docs --exports
```
2. Import the generated file from your project output (example path):
```dart
import 'package:your_app/src/analytics/generated/analytics.dart';
```
3. Verify `analytics_gen.outputs.dart` in `analytics_gen.yaml` matches your import.

### `Analytics.initialize(...) must be called before logging events`
**Cause**: You are using the singleton API without initialization.
**Fix**: Call `Analytics.initialize(yourProvider)` once during bootstrap (and `Analytics.reset()` in tests).

### `Syntax Error: Expected to find ')'`
**Cause**: Rarely, complex regex strings or unescaped quotes in descriptions can break generation.
**Fix**: Ensure quotes in YAML descriptions are escaped or use block strings (`|`).
```yaml
description: |
  User's "display" name.
```

## IDE / Editor Issues

### Analysis Errors in Generated Files
**Cause**: `analyzer` hasn't refreshed the file system.
**Fix**:
1. Run `dart analyze`.
2. Restart Dart Analysis Server in your IDE.

## Getting Help

If you encounter a bug:
1. Run with `--verbose` to get full stack traces.
2. Open an issue on GitHub with the verbose output and the reproduction YAML.
