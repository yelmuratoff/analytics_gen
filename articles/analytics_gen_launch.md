<div align="center">
  <h1>Stop Writing Analytics Code. Start Defining It.</h1>

  <a href="https://pub.dev/packages/analytics_gen">
    <img src="https://github.com/yelmuratoff/analytics_gen/blob/main/assets/analytics_gen_banner.png?raw=true" width="600">
  </a>

  <h3>Type-safe analytics, automated documentation, and data integrity-from a single source of truth.</h3>
</div>

---

As a Developer who has seen the inside of massive codebases, I've witnessed the same tragedy play out in almost every product team.

> It starts innocently. A Product Manager asks for a new event: `user_clicked_button`.
> A developer adds `analytics.logEvent('user_clicked_button')`.
> A week later, another developer adds `analytics.logEvent('UserClickedButton')`.
> A month later, a data analyst asks why the `button_id` parameter is a string in iOS but an integer in Android.
> **Six months later, your dashboard is a graveyard of untrustworthy data.**

We treat our production code with rigor-CI/CD, type safety, code reviews. Yet we treat our analytics-the very data that drives our business decisions-like a "stringly typed" afterthought.

**It's time to stop writing analytics code by hand.**

Meet **`analytics_gen`**, a tool designed to bring engineering discipline to your data pipeline.

## The Philosophy: Schema First

The core problem with analytics is **drift**. The implementation drifts from the spec, the docs drift from the code, and the platforms drift from each other.

`analytics_gen` solves this by enforcing a **Single Source of Truth**. You define your analytics plan in YAML, and the tool generates everything else.

### 1. Type-Safe Dart Code
Instead of guessing event names and parameter keys, you get a generated, type-safe API.

**❌ Before (The "Stringly Typed" Nightmare):**
```dart
// Hope you spelled 'purchase_completed' right...
// And is 'value' a double or an int?
analytics.logEvent('purchase_completed', {'value': 99.99});
```

**✅ After (The `analytics_gen` Way):**
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
# events/search.yaml
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
- 📘 **Markdown Docs**: Always up-to-date, readable descriptions of every event and parameter.
- 📊 **CSV/JSON Exports**: Machine-readable schemas that can be ingested by your data warehouse (BigQuery, Snowflake) to validate incoming data.
- 🗄️ **SQL Schemas**: Ready-to-run `CREATE TABLE` statements.

## Built for Scale

I built `analytics_gen` with the constraints of large-scale engineering in mind.

- **Domain Splitting**: Break your plan into multiple YAML files (e.g., `auth.yaml`, `checkout.yaml`) so different teams can own their domains without merge conflict hell.
- **Shared Parameters**: Define `user_id` or `session_id` once in `shared.yaml` and reuse them everywhere. **DRY** applied to data.
- **Dual-Write Migration**: Changing event names or structures? Use `dual_write_to` to log to both the old and new events simultaneously during the transition, ensuring zero data loss.

## Architecture: Flexible & Robust

The generated code doesn't lock you into a specific provider. It sits *above* your SDKs.

- 🔌 **Multi-Provider Support**: Send the same event to Firebase, Amplitude, and your internal warehouse with a single call.
- ⚡ **Async & Batching**: The generated API is synchronous (fire-and-forget) so it never blocks your UI, but the backend supports async buffering, retries, and batching for network efficiency.
- 🌍 **Contexts**: Manage global state (like `user_role` or `theme`) separately from ephemeral events.

## Try It Out

If you're tired of debugging why your funnel drop-off looks wrong, or if you just want the same level of tooling for your data as you have for your app logic, give `analytics_gen` a try.

It's not just a code generator; it's a contract between your code and your data.

<div align="center">

**[Get started on pub.dev](https://pub.dev/packages/analytics_gen)** • **[Star on GitHub](https://github.com/yelmuratoff/analytics_gen)**

</div>

---

Small post:

Stop treating analytics like a "stringly typed" afterthought. 📉

We enforce strict types for app logic, yet our data pipelines often rely on copy-pasted strings and hope. A single typo can turn your dashboard into a graveyard of untrustworthy data.

Meet analytics_gen. 🚀
The philosophy is simple: Schema First. You define your analytics plan in YAML, and the tool generates the rest.

Here is the difference:

1️⃣ Type-Safe Dart Code
Instead of guessing event names:
analytics.logEvent('purchase', {'val': 99}) ❌

You get compile-time checked methods:
analytics.logPurchase(value: 99.99) ✅

If you change the schema, the build fails. No more silent regressions.

2️⃣ Validation at the Source
Garbage in, garbage out. Define rules (regex, min_length) in your schema. The generated code catches bad data *before* it leaves the user's device.

3️⃣ Automated Documentation
Keep PMs and Analysts in sync without manual effort.
Automatically generate:
• 📘 Markdown documentation
• 📊 CSV/JSON exports for data warehouses
• 🗄 SQL schemas for immediate ingestion

🏗 Built for Scale
Designed for large codebases with support for domain splitting (auth.yaml, payment.yaml) and dual-write migration strategies.

It's a contract between your code and your data.

👇 Check it out:
📦 Pub.dev: https://pub.dev/packages/analytics_gen
⭐️ GitHub: https://github.com/yelmuratoff/analytics_gen

#Flutter #Dart #Analytics #DataEngineering #OpenSource #MobileDev #SoftwareEngineering