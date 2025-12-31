# Stop Debugging Analytics. Start Defining It.

**We demand strict contracts for our APIs. It's time our analytics got the same treatment.**

![Main Banner](https://github.com/yelmuratoff/analytics_gen/blob/main/assets/analytics_gen_banner.png?raw=true)

---

Imagine this scenario: You launch a new feature. The UI is polished, the animations are 60fps, and the unit tests are green. You go to sleep.

Next morning, the Product Manager pings you: *"Hey, the revenue dashboard shows zero growth. Did the feature fail?"*

You panic. You check Stripe-money is flowing. You check the backend-orders are created. Finally, you dig into the analytics code and find the culprit.

*   The **Cart Checkout** logs: `{'value': 49.99, 'currency': 'USD'}`
*   The new **One-Click Buy** logs: `{'price': 49.99, 'currency_code': 'USD'}`

Two developers. Two features. Same event. **Completely different parameters.**

Because of this mismatch, your Data Analyst's SQL query (`SUM(value)`) ignored 100% of the new revenue. The report is wrong. The trust is damaged.

This is the **"Stringly Typed" Trap**. And there is a better way.

## The Hidden Cost of Strings

In many Flutter projects, analytics is treated as a second-class citizen. It's often implemented like this:

```dart
// ❌ The "Stringly Typed" Nightmare
analytics.logEvent('add_to_cart', {
  'item_id': 'sku_123',
  'quantity': 1,
  'price': '99.99', // Wait, is this a String or Double?
});
```

This approach has three fatal flaws:
1.  **No Type Safety**: You can send a `String` where a `Double` is expected.
2.  **No Validation**: You can send an empty `item_id` or a negative `quantity`.
3.  **Documentation Drift**: The Confluence page says the parameter is `currency_code`, but the code sends `currency`. Who is right?

## The Solution: Schema-First Development

We solved this problem for APIs with tools like Swagger/OpenAPI and GraphQL. We define a **contract** (schema), and we generate the code.

**`analytics_gen`** brings this same discipline to your analytics pipeline.

Instead of writing Dart code manually, you define your events in a YAML schema. This schema becomes the **Single Source of Truth**.

### 1. Define the Contract

Here is how a robust event definition looks in `analytics_gen`:

```yaml
# events/commerce.yaml
commerce:
  purchase_completed:
    description: "Triggered when a user completes a payment."
    parameters:
      transaction_id:
        type: string
        min_length: 10
      value:
        type: double
        min: 0.01
      currency:
        type: string
        allowed_values: ['USD', 'EUR', 'GBP'] # Generates an Enum!
      items_count:
        type: int
```

### 2. Generate the Code

Running `dart run analytics_gen:generate` produces a strictly typed Dart API.

```dart
/// Generated mixin for commerce analytics events
mixin AnalyticsCommerce on AnalyticsBase {
  /// Triggered when a user completes a payment.
  ///
  /// Parameters:
  /// - `currency`: AnalyticsCommercePurchaseCompletedCurrencyEnum
  /// - `items_count`: int
  /// - `transaction_id`: String
  /// - `value`: double
  void logCommercePurchaseCompleted({
    required AnalyticsCommercePurchaseCompletedCurrencyEnum currency,
    required int itemsCount,
    required String transactionId,
    required double value,
    Map<String, Object?>? parameters,
  }) {
    if (transactionId.length < 10) {
      throw ArgumentError.value(
        transactionId,
        'transactionId',
        'length must be at least 10',
      );
    }

    if (value < 0.01) {
      throw ArgumentError.value(
        value,
        'value',
        'must be at least 0.01',
      );
    }

    final eventParameters = <String, Object?>{
      'description': 'Triggered when a user completes a payment.',
      "currency": currency.value,
      "items_count": itemsCount,
      "transaction_id": transactionId,
      "value": value,
    }..addAll(parameters ?? const {});

    logger.logEvent(
      name: "commerce_purchase_completed",
      parameters: eventParameters,
    );
  }
}
```

If you try to pass a `String` to `value`, the code won't compile. If you try to pass "YEN" as a currency, the code won't compile.

### 3. Runtime Validation (The Safety Net)

Type safety catches bugs at compile time, but what about runtime data? What if `transaction_id` comes from a backend response and is empty?

`analytics_gen` automatically generates assertions and validations based on your YAML rules (`min_length`, `regex`, `min/max`).

```dart
// Inside the generated code:
if (transactionId.length < 10) {
  throw ArgumentError.value(
    transactionId,
    'transactionId',
    'must be at least 10 characters',
  );
}
```

Bad data is caught **on the client**, in debug mode, before it ever pollutes your data warehouse.

## How It Works

![Usage Image](https://github.com/yelmuratoff/analytics_gen/blob/main/assets/banner_v2.png?raw=true)


## Beyond Code: The "Bus Factor"

The biggest hidden cost of analytics is knowledge transfer. When the developer who implemented `checkout_v2` leaves, who knows what the `status` parameter means?

`analytics_gen` solves this by auto-generating documentation alongside your code.

*   **Markdown Docs**: A `README.md` file that lists every event, parameter, and description. It lives in your repo and updates with every PR.
*   **Data Dictionary**: It can generate JSON/CSV schemas that you can upload to Segment, Amplitude, or your Data Warehouse to validate ingestion.

## Real World Migration Strategy

"This sounds great, but I have an existing app with 500 events. I can't rewrite everything."

You don't have to. `analytics_gen` is designed for **incremental adoption**.

1.  **Domain Splitting**: You don't need one giant file. Create `auth.yaml`, `profile.yaml`, `commerce.yaml`. Start with just one domain.
2.  **Dual Write**: Migrating event names? Use the `dual_write_to` feature to send data to both the old and new event names simultaneously during the transition period.

```yaml
events:
  login_success:
    # Logs to both 'login_success' AND 'user_logged_in'
    dual_write_to: ['user_logged_in']
```

## Conclusion

Analytics is not just "logging". It is the eyes and ears of your product. If your analytics are blurry (untyped) or hallucinating (invalid data), your product decisions will be wrong.

Stop treating analytics as an afterthought. Treat it as code. Define the schema, generate the implementation, and never worry about a typo breaking your funnel again.

---

**Ready to clean up your data pipeline?**

📦 **Pub.dev**: [analytics_gen](https://pub.dev/packages/analytics_gen)
⭐️ **GitHub**: [yelmuratoff/analytics_gen](https://github.com/yelmuratoff/analytics_gen)

#Flutter #Dart #DataEngineering #CodeGeneration #MobileDev #Analytics
