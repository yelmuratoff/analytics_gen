# Analytics Gen Example App

This example now ships as a runnable Flutter app so you can exercise the generated analytics mixins with real UI interactions.

## Prerequisites

- Flutter 3.22+ with macOS/iOS/Android/Web tooling installed.
- Dart 3.9+ (comes with Flutter).

## Project Structure

```
example/
├── analytics_gen.yaml      # Generator config (shared with CI)
├── events/                 # YAML tracking plan (auth, screen, purchase)
├── lib/
│   ├── src/app/            # Flutter widgets, controller, observable adapter
│   └── src/analytics/      # Generated analytics API (do not edit)
├── test/                   # Flutter widget tests asserting analytics wiring
├── docs/                   # Generated Markdown docs
├── assets/generated/       # Exports (CSV/JSON/SQL/SQLite)
└── README.md               # This file
```

## Setup

```bash
cd example
flutter pub get
# Ensure the analytics outputs are fresh
dart run analytics_gen:generate --docs --exports
```

> The generator runs fine under `flutter pub run` because the example depends on the local `analytics_gen` package via a path dependency.

## Running the Flutter App

```bash
flutter run -d macos      # Or chrome, ios, android
```

Tap any button to trigger the strongly typed analytics events. The buttons call domain-centric controller methods (e.g., `purchaseMonthlySubscription`) so UI code stays declarative. The event log at the bottom shows what was emitted, and `MockAnalyticsService.verbose` writes the payloads to stdout.

## Tests

```bash
flutter test
```

Widget tests in `test/widget_test.dart` verify the generated mixins hook into the UI correctly (e.g., tapping "Login" records the `auth: login` event).

## Regenerating Artifacts

```bash
flutter pub run analytics_gen:generate --docs --exports
```

- The generated Dart lives under `lib/src/analytics/generated/`.
- Docs land in `docs/analytics_events.md`.
- Exports go to `assets/generated/`.

Commit updated artifacts so reviewers can diff YAML changes alongside code/doc/export updates.

## Troubleshooting

- Missing Flutter desktop targets? Run `flutter config --enable-macos-desktop` (or the platform you need).
- Deprecated event warnings (e.g., `logAuthLogin`) come from the tracking plan itself—use them to practice migrations.
- If `flutter run` complains about missing generated files, re-run the generator command above.
