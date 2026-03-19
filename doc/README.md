# Documentation for `analytics_gen`

Welcome to the documentation for the **analytics_gen** package. This folder contains additional guides and reference material that complement the README and the automatically generated API reference.

## Contents

- [Onboarding Guide](ONBOARDING.md) – How to get started with the package.
- [Schema Reference](SCHEMA_REFERENCE.md) – Auto-generated reference for all YAML fields, types, and defaults.
- [Validation & Naming](VALIDATION.md) – Schema validation rules and naming conventions.
- [Naming & Configuration](NAMING.md) – Naming strategies, templates, and casing options.
- [Capabilities](CAPABILITIES.md) – Overview of capability keys and provider integration.
- [Migration Guides](MIGRATION_GUIDES.md) – Steps to migrate existing analytics implementations.
- [Code Review Checklist](CODE_REVIEW.md) – Checklist for reviewing generated code and docs.
- [Testing Guide](TESTING.md) – Testing patterns for generated analytics APIs and providers.
- [Scalability & Performance](SCALABILITY.md) – Performance considerations for large plans.
- [Performance](PERFORMANCE.md) – Detailed optimization tips.
- [Troubleshooting](TROUBLESHOOTING.md) – Common errors and fixes.
- [AI Prompt Guide](PROMPT_GUIDE.md) – "System prompt" to help LLMs generate valid YAML for you.
- [API Reference](https://pub.dev/documentation/analytics_gen/latest/) – Generated Dart API docs on pub.dev.

## Schema Infrastructure

JSON schemas in `schema/` are the single source of truth. Generated artifacts:

| Artifact | Command |
|----------|---------|
| YAML templates (`templates/`) | `dart run scripts/generate_templates.dart` |
| This schema reference doc | `dart run scripts/generate_schema_docs.dart` |
| Studio TypeScript types | `cd analytics-gen-studio && npm run generate-types` |
| Full sync + verify | `./scripts/sync.sh` |

## Studio (Web UI)

The `analytics-gen-studio/` directory contains a visual editor. See the main [README](../README.md#studio-web-ui) for details.
