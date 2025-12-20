# Performance Guide

This guide provides strategies for optimizing the performance of `analytics_gen` and the code it generates.

## Build Performance (CLI)

The `analytics_gen` CLI is designed to be fast, but large projects (1000+ events) can see slowdowns.

### Benchmarks (Typical)
| Events | Parsing | Generation | Total Time |
|--------|---------|------------|------------|
| 100    | ~50ms   | ~20ms      | ~100ms     |
| 1000   | ~300ms  | ~150ms     | ~500ms     |
| 5000   | ~1.5s   | ~800ms     | ~2.5s      |

### Optimization Tips

1.  **Use `--metrics` flag**:
    Run with `dart run analytics_gen:generate --metrics` to identify slow phases.

2.  **Modularize YAML files**:
    Instead of one huge `events.yaml`, split by feature (e.g., `events/auth.yaml`, `events/payment.yaml`). This allows parallel parsing and better caching (in future versions).

3.  **Avoid Deeply Nested Contexts**:
    Complex context parameters increase validation overhead. Keep context depth to 1-2 levels.

## Runtime Performance (Generated Code)

The generated code is optimized for zero-allocation where possible and low CPU usage.

### Zero-Runtime Reflection
`analytics_gen` uses strictly **static code generation**. No `mirrors` or runtime reflection is used, ensuring:
- Tree-shaking support
- Fast startup
- Minimal app size impact

### Static Regex Compilation
Regex patterns for parameter validation are compiled `static final` fields in the generated mixins. They are compiled once per app lifecycle, not per event call.

```dart
static final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
```

### String Interpolation vs. Concatenation
Events with dynamic names (e.g., `page_view_{id}`) use highly optimized string interpolation.
*Note: We recommend using parameters instead of dynamic event names to avoid high cardinality in your analytics backend.*

## Binary Size Impact

Generated code is verbose but highly compressible.
- **Tree Shaking**: Only events you actually call are included in the final binary (if you use specific mixins).
- **ProGuard/R8**: Obfuscation works seamlessly as there is no reflection.

### Reducing Size
If your generated file is too large:
1.  **Use `generate_exports: false`**: If you don't need CSV/JSON exports, disable them in `analytics_gen.yaml`.
2.  **Use `generate_docs: false`**: Inline documentation comments add size to source (but not binary).
