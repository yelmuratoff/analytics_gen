# TODO: Technical Debt and Improvements (Completed)

## Critical Fixes (P0/P1)

- [x] **CI Recovery**: Fix `dart analyze --fatal-infos` failure.
- [x] **Documentation Sync**: Bring README, ONBOARDING, and TROUBLESHOOTING in sync with reality.
- [x] **Code Generation Vulnerabilities**: String/Regex escaping and multiline descriptions.
- [x] **Schema Evolution**: Fix JSON key mismatch: `'nullable'` → `'is_nullable'`.
- [x] **Web Protection**: Guard `dart:io` usages.
- [x] **CLI Validation Parity (P0)**: Unified parsing via `TrackingPlanLoader` for identical behavior between generation and validation.
- [x] **Fingerprint Correctness (P0)**: Fingerprints now cover all meaningful plan changes and config settings.
- [x] **Cross-Platform File Filtering (P1)**: Standardized absolute path normalization in `EventLoader`.

## Technical Debt & Refactoring (P2)

- [x] **MultiProviderAnalytics**: Fixed discrepancy between doc and implementation.
- [x] **Export Cleanup**: Extended stale file cleanup in `export_generator.dart`.
- [x] **Orphaned Doc Comment**: Removed in `analytics_parameter.dart`.
- [x] **Renderer Cleanup (P2)**: Consolidated `MethodSignatureRenderer` and removed duplication.
- [x] **Docs Parity (P2)**: Updated onboarding to recommend `dependencies` for mandatory runtime usage.
- [x] **Docs Hygiene (P2)**: Fixed broken references in `SCALABILITY.md` and updated config templates.
- [x] **Repo Hygiene (P2)**: Removed `.DS_Store` and updated `.gitignore`.

## Features / Improvements

- [ ] **Glob Support**: Consider adding real glob support to `EventLoader` to match documentation.
