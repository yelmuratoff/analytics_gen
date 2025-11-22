# Stop Writing Analytics Code. Start Defining It.

<img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/analytics_gen.png?raw=true" width="400">

**Type-safe analytics, automated documentation, and data integrity—from a single source of truth.**

---

As a Developer who has seen the inside of massive codebases, I’ve witnessed the same tragedy play out in almost every product team.

It starts innocently. A Product Manager asks for a new event: `user_clicked_button`.
A developer adds `analytics.logEvent('user_clicked_button')`.
A week later, another developer adds `analytics.logEvent('UserClickedButton')`.
A month later, a data analyst asks why the `button_id` parameter is a string in iOS but an integer in Android.
Six months later, your dashboard is a graveyard of untrustworthy data, and no one knows which events are actually live.

We treat our production code with rigor—CI/CD, type safety, code reviews. Yet we treat our analytics—the very data that drives our business decisions—like a string-ly typed afterthought.

**It’s time to stop writing analytics code by hand.**

Meet **`analytics_gen`**, a tool designed to bring engineering discipline to your data pipeline.

## The Philosophy: Schema First

The core problem with analytics is drift. The implementation drifts from the spec, the docs drift from the code, and the platforms drift from each other.

`analytics_gen` solves this by enforcing a **Single Source of Truth**. You define your analytics plan in YAML, and the tool generates everything else.

### 1. Type-Safe Dart Code
Instead of guessing event names and parameter keys, you get a generated, type-safe API.

**Before (The "Stringly Typed" Nightmare):**
```dart
// Hope you spelled 'purchase_completed' right...
// And is 'value' a double or an int?
analytics.logEvent('purchase_completed', {'value': 99.99});
```

**After (The `analytics_gen` Way):**
```dart
// Compile-time checked. Autocompleted. Documented.
analytics.logPurchaseCompleted(
  value: 99.99,
  currency: 'USD',
  itemCount: 3,
);
```

If you change a parameter in the YAML, your build fails until you update the code. No more silent regressions.

### 2. Validation at the Source
Garbage in, garbage out. If your analytics ingestion pipeline is receiving bad data, your charts are lying to you. `analytics_gen` lets you define validation rules directly in your schema.

```yaml
search_event:
  parameters:
    query:
      type: string
      min_length: 3
      regex: "^[a-zA-Z0-9 ]+$"
    category:
      type: string
      allowed_values: ['electronics', 'books', 'clothing']
```

The generator creates runtime checks that enforce these rules *before* the event leaves the client. It also generates Dart `enums` for `allowed_values`, making invalid states unrepresentable.

### 3. Automated Documentation & Exports
Your stakeholders (PMs, Data Analysts) don't read Dart code. They need documentation.
`analytics_gen` automatically generates:
- **Markdown Docs**: Always up-to-date, readable descriptions of every event and parameter.
- **CSV/JSON Exports**: Machine-readable schemas that can be ingested by your data warehouse (BigQuery, Snowflake) to validate incoming data.
- **SQL Schemas**: Ready-to-run `CREATE TABLE` statements.

## Built for Scale

I built `analytics_gen` with the constraints of large-scale engineering in mind.

- **Domain Splitting**: Break your plan into multiple YAML files (e.g., `auth.yaml`, `checkout.yaml`) so different teams can own their domains without merge conflict hell.
- **Shared Parameters**: Define `user_id` or `session_id` once in `shared.yaml` and reuse them everywhere. DRY applied to data.
- **Dual-Write Migration**: changing event names or structures? Use `dual_write_to` to log to both the old and new events simultaneously during the transition, ensuring zero data loss.

## Architecture: Flexible & Robust

The generated code doesn't lock you into a specific provider. It sits *above* your SDKs.

- **Multi-Provider Support**: Send the same event to Firebase, Amplitude, and your internal warehouse with a single call.
- **Async & Batching**: The generated API is synchronous (fire-and-forget) so it never blocks your UI, but the backend supports async buffering, retries, and batching for network efficiency.
- **Contexts**: Manage global state (like `user_role` or `theme`) separately from ephemeral events.

## Try It Out

If you’re tired of debugging why your funnel drop-off looks wrong, or if you just want the same level of tooling for your data as you have for your app logic, give `analytics_gen` a try.

It’s not just a code generator; it’s a contract between your code and your data.

- **Get started on pub.dev:** [pub.dev/packages/analytics_gen](https://pub.dev/packages/analytics_gen)
- **Star on GitHub:** [github.com/yelmuratoff/analytics_gen](https://github.com/yelmuratoff/analytics_gen)
