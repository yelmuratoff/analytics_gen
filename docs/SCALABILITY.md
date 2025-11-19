# Scalability & Performance

`analytics_gen` is optimized for large-scale tracking plans. This document provides benchmark data to help enterprise teams understand performance characteristics and tuning options.

## Benchmark Results

Tests were performed on a standard developer machine (Apple Silicon) using synthetic event definitions (10 events per domain, 3 parameters per event).

| Total Events | Domains | Generation Time | Files Generated |
|--------------|---------|-----------------|-----------------|
| **100**      | 10      | ~1.0s           | 12              |
| **500**      | 50      | ~1.6s           | 52              |
| **2,000**    | 200     | ~4.0s           | 202             |
| **10,000**   | 1,000   | ~18.3s          | 1,002           |

### Key Takeaways

1.  **Linear Scaling**: Performance scales linearly with the number of events/domains.
2.  **Fast Iteration**: Small to medium plans (<500 events) generate in under 2 seconds.
3.  **Enterprise Ready**: Even massive plans (10,000 events) complete in <20 seconds, making it suitable for CI/CD pipelines.

## Recommendations

### For Large Plans (1000+ Events)

*   **Modularize**: Split events into domain-specific YAML files. The tool processes them in parallel where possible.
*   **Use Watch Mode**: `dart run analytics_gen:generate --watch` avoids full CLI startup overhead during development.
*   **CI/CD**: For plans >5,000 events, consider caching the `pub get` step to keep total build times low.
