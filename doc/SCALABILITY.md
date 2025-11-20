# Scalability & Performance

`analytics_gen` is optimized for large-scale tracking plans. This document provides benchmark data to help enterprise teams understand performance characteristics and tuning options.

## Benchmark Results

Tests were performed on a standard developer machine (Apple M1 Pro 10-core, 16GB RAM, Dart 3.3.0) using synthetic event definitions (10 events per domain, 3 parameters per event).

| Total Events | Domains | Generation Time | Files Generated |
|--------------|---------|-----------------|-----------------|
| **100**      | 10      | ~0.9s           | 12              |
| **500**      | 50      | ~1.3s           | 52              |
| **2,000**    | 200     | ~3.3s           | 202             |
| **10,000**   | 1,000   | ~14.3s          | 1,002           |

> **Note**: CI runners may be slower due to shared resources. To reproduce these results, run `dart tool/benchmark.dart` (if available) or generate a synthetic plan with `tool/gen_synthetic_plan.dart`.

### Key Takeaways

1.  **Linear Scaling**: Performance scales linearly with the number of events/domains.
2.  **Fast Iteration**: Small to medium plans (<500 events) generate in under 1.5 seconds.
3.  **Enterprise Ready**: Even massive plans (10,000 events) complete in <15 seconds, making it suitable for CI/CD pipelines.
4.  **Optimized I/O**: The generator uses parallel processing and incremental file writes (only touching files if content changes) to minimize disk I/O and preserve build caches.

## Recommendations

### For Large Plans (1000+ Events)

*   **Modularize**: Split events into domain-specific YAML files. The tool processes them in parallel where possible.
*   **Use Watch Mode**: `dart run analytics_gen:generate --watch` avoids full CLI startup overhead during development.
*   **CI/CD**: For plans >5,000 events, consider caching the `pub get` step to keep total build times low.
