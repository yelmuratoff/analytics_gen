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
**Fix**: Move the parameter definition to a file listed in `shared_parameter_paths` or disable the rule.

### `Exit code 255` or `Stack Overflow`
**Cause**: Circular dependencies in YAML imports or extremely deep nesting.
**Fix**: Check `rules: prevent_event_parameter_duplicates`. Simplify YAML structure.

## Generated Code Issues

### `The method 'log...' isn't defined for the type 'Analytics'`
**Cause**:
1. You haven't run the generator: `dart run analytics_gen:generate`
2. You haven't mixed in the generated domain mixin to your `Analytics` class.
**Fix**:
Update your `Analytics` class:
```dart
class Analytics extends AnalyticsBase with AnalyticsAuth, AnalyticsPayment { ... }
```

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
