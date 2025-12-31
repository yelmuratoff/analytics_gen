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