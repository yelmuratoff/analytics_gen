---
name: validate
description: Run full validation — dart analyze, dart test, studio build, schema consistency checks. Trigger on "/validate".
---

# Validate

Run all checks to ensure project is healthy.

## Steps (run in parallel where possible)

1. **Dart analyze**: `dart analyze lib/ bin/ test/`
2. **Dart tests**: `dart test`
3. **Studio build**: `cd analytics-gen-studio && npm run build`
4. **Studio tests**: `cd analytics-gen-studio && npx vitest run`

## Report

```
Dart analyze:  ✅ 0 issues / ⚠️ N issues
Dart tests:    ✅ N passed / ❌ N failed
Studio build:  ✅ success / ❌ errors
Studio tests:  ✅ N passed / ❌ N failed
```

If any step fails, show the errors and suggest fixes.
