# How to Safely Deprecate Analytics Events in Flutter (Stop Hoarding Data)

We are all guilty of "Data Hoarding".

You know the drill:
1.  A feature changes.
2.  The old `checkout_completed` event is no longer relevant.
3.  We create a new `order_placed` event.
4.  **But we don't delete the old one.**

Why? Because "what if the Data Team still needs it?" or "I don't want to break the build if it's used somewhere else."

So the codebase grows. The dashboard becomes a graveyard of zombie events. New developers don't know which one to use.

**It's time to treat Analytics like code: with a proper lifecycle.**

### The "Zombie Event" Problem

When you use magic strings for analytics, deprecation is impossible.

```dart
// Is this still used? Who knows.
analytics.logEvent('checkout_completed_v1'); 
```

You can't mark a string literal as `@Deprecated`. You can't find all usages easily. You just leave it there, "just in case".

### The Solution: Schema-Driven Deprecation

With `analytics_gen`, you manage the lifecycle of your data in your YAML schema. You don't just add events; you **kill** them gracefully.

#### Step 1: Mark it in YAML

When an event reaches the end of its life, you don't delete it immediately. You mark it as deprecated and point to the replacement.

```yaml
# events/purchase.yaml
events:
  checkout_completed:
    description: "Old checkout event. Use order_placed instead."
    deprecated: true
    replacement: "order_placed" # The tool knows what this means!
    
  order_placed:
    description: "New standard order event."
    parameters:
      order_id: String
```

#### Step 2: The Tool Does the Heavy Lifting

When you run the generator, it produces Dart code that leverages the language's built-in deprecation features:

```dart
// Generated Code

@Deprecated('Old checkout event. Use order_placed instead.')
void logCheckoutCompleted() {
  // ... implementation
}

void logOrderPlaced({required String orderId}) {
  // ... implementation
}
```

#### Step 3: The IDE Helps You Clean Up

Now, every developer using the old event sees a **strikethrough** in their IDE.

> `analytics.logCheckoutCompleted()`

Hovering over it shows the message: *"Use order_placed instead."*

You have effectively communicated the migration plan to the entire engineering team without holding a meeting or writing a wiki page that no one reads.

### Safe Removal

Once you've migrated all call sites (which is easy, because the compiler warns you about them), you can safely delete the event from the YAML. If you missed one spot, the build fails.

**No more zombies. No more guessing.**

### Summary

Great codebases aren't just about what you add; they're about what you delete. `analytics_gen` gives you the confidence to prune your analytics implementation, keeping your data schema as clean as your architecture.

[IMAGE PROMPT: A split screen comparison. Left side: A dark, cobweb-filled room labeled "Legacy Analytics" with piles of dusty boxes labeled "v1", "v2_final", "deprecated?". Right side: A bright, clean minimalist room labeled "Schema-First" with a recycling bin icon and a clear path forward. 3D isometric style, clean lines, tech blue and white colors.]

---

**Start cleaning up your data:**
📦 **Pub.dev**: [analytics_gen](https://pub.dev/packages/analytics_gen)
⭐️ **GitHub**: [yelmuratoff/analytics_gen](https://github.com/yelmuratoff/analytics_gen)

#Flutter #Dart #Refactoring #DataEngineering #CleanCode #MobileDev
