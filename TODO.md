# TODO: Technical Debt and Improvements

## Documentation Fixes

- [ ] **README.md:67** — Fix config key: `outputs.path` → `outputs.dart`
- [ ] **TROUBLESHOOTING.md:18** — Fix config key: `shared_parameter_paths` → `shared_parameters`
- [ ] **ONBOARDING.md:68** — Remove duplicate `targets:` block (lines 68-71)

## Code Quality

- [ ] **schema_comparator.dart:284** — Fix JSON key mismatch: `'nullable'` → `'is_nullable'` to match `serialization.dart:143`
- [ ] **export_generator.dart:53-70** — Extend CSV cleanup to delete all 6 generated CSV files, not just `analytics_events.csv`

## Minor Cleanup (Optional)

- [ ] **analytics_parameter.dart:88** — Remove orphaned doc comment `/// Parses a list of parameters from a YAML map.`
