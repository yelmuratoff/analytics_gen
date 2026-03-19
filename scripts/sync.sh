#!/bin/bash
set +e  # Don't exit on error — we track failures manually

# ─────────────────────────────────────────────────────────────
# sync.sh — Single source of truth pipeline
#
# Regenerates everything from schema/, runs all checks.
# Run from project root: ./scripts/sync.sh
# ─────────────────────────────────────────────────────────────

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

passed=0
failed=0

step() {
  echo ""
  echo -e "${CYAN}── $1 ──${NC}"
}

ok() {
  echo -e "  ${GREEN}✓${NC} $1"
  ((passed++))
}

fail() {
  echo -e "  ${RED}✗${NC} $1"
  ((failed++))
}

# ─── 1. Generate from schemas ───

step "Generate templates from schemas"
if dart run scripts/generate_templates.dart; then
  ok "templates/*.yaml"
else
  fail "templates generation failed"
fi

step "Generate schema docs"
if dart run scripts/generate_schema_docs.dart; then
  ok "doc/SCHEMA_REFERENCE.md"
else
  fail "docs generation failed"
fi

# ─── 2. Generate API documentation (dartdoc) ───

step "Generate API docs (dart doc)"
if dart doc 2>&1 | grep -q "Success!"; then
  TOPIC_COUNT=$(ls doc/api/topics/*-topic.html 2>/dev/null | wc -l | tr -d ' ')
  ok "doc/api/ — $TOPIC_COUNT topic pages"
else
  dart doc 2>&1 | grep -E "error|warning" | tail -5
  fail "dart doc failed"
fi

# ─── 3. Dart library checks ───

step "Dart analyze"
if dart analyze lib/ bin/ test/ 2>&1 | tail -1 | grep -q "No issues"; then
  ok "dart analyze — 0 issues"
else
  dart analyze lib/ bin/ test/ 2>&1 | tail -5
  fail "dart analyze found issues"
fi

step "Dart tests"
DART_TEST_OUTPUT=$(dart test 2>&1 | tr '\r' '\n')
DART_RESULT=$(echo "$DART_TEST_OUTPUT" | grep -E "All tests|Some tests" | tail -1)
if echo "$DART_RESULT" | grep -q "All tests passed"; then
  TEST_COUNT=$(echo "$DART_RESULT" | grep -oE '\+[0-9]+' | head -1)
  ok "dart test — ${TEST_COUNT} passed"
else
  echo "$DART_TEST_OUTPUT" | grep -E "failed|Error" | tail -5
  fail "dart test — some tests failed"
fi

# ─── 4. Sync schemas & docs to Studio ───

step "Copy schemas to Studio"
if [ -d "analytics-gen-studio/public/schemas" ]; then
  cp schema/*.json analytics-gen-studio/public/schemas/
  ok "schema/*.json → analytics-gen-studio/public/schemas/"
else
  fail "analytics-gen-studio/public/schemas/ not found"
fi

step "Copy API docs to Studio"
if [ -d "doc/api" ]; then
  rm -rf analytics-gen-studio/public/docs
  cp -r doc/api analytics-gen-studio/public/docs
  FIX_OUTPUT=$(cd analytics-gen-studio && node scripts/fix-docs-redirects.mjs 2>&1)
  ok "doc/api/ → analytics-gen-studio/public/docs/ ($FIX_OUTPUT)"
else
  fail "doc/api/ not found — run 'dart doc' first"
fi

# ─── 5. Studio checks ───

step "Studio: generate TypeScript types"
cd analytics-gen-studio
if node scripts/generate-types.mjs 2>&1 | grep -q "Generated"; then
  ok "src/types/generated.ts"
else
  fail "TypeScript type generation failed"
fi

step "Studio: TypeScript check"
TSC_OUTPUT=$(npx tsc --noEmit 2>&1)
TSC_EXIT=$?
if [ "$TSC_EXIT" -eq 0 ]; then
  ok "tsc --noEmit — 0 errors"
else
  echo "$TSC_OUTPUT" | head -5
  fail "TypeScript errors found"
fi

step "Studio: tests"
STUDIO_TEST_OUTPUT=$(npx vitest run 2>&1)
if echo "$STUDIO_TEST_OUTPUT" | grep -q "passed"; then
  TEST_LINE=$(echo "$STUDIO_TEST_OUTPUT" | grep "Tests" | tail -1)
  ok "vitest — $TEST_LINE"
else
  echo "$STUDIO_TEST_OUTPUT" | grep -E "FAIL|Error" | tail -5
  fail "Studio tests failed"
fi

step "Studio: production build"
if npm run build 2>&1 | grep -q "built in"; then
  ok "vite build"
else
  npm run build 2>&1 | grep "error" | head -5
  fail "Studio build failed"
fi

cd "$ROOT"

# ─── 6. Cross-reference check ───

step "Schema ↔ YamlKeys cross-reference"
MISSING=$(node -e "
const fs = require('fs');
const keys = fs.readFileSync('lib/src/util/yaml_keys.dart','utf8');
const config = JSON.parse(fs.readFileSync('schema/analytics_gen.schema.json','utf8'));
const events = JSON.parse(fs.readFileSync('schema/events.schema.json','utf8'));
const param = JSON.parse(fs.readFileSync('schema/parameter.schema.json','utf8'));
const missing = [];
const root = config.properties.analytics_gen.properties;
for (const [sec, v] of Object.entries(root)) {
  if (v['x-alias-for']) continue;
  if (!keys.includes(\"'\" + sec + \"'\")) missing.push(sec);
  if (v.type === 'object' && v.properties) {
    for (const f of Object.keys(v.properties)) {
      if (!keys.includes(\"'\" + f + \"'\")) missing.push(sec + '.' + f);
    }
  }
}
for (const f of Object.keys(events['\$defs'].event.properties)) {
  if (!keys.includes(\"'\" + f + \"'\")) missing.push('event.' + f);
}
for (const f of Object.keys(param.properties)) {
  if (!keys.includes(\"'\" + f + \"'\")) missing.push('param.' + f);
}
if (missing.length) console.log(missing.join(', '));
" 2>&1)

if [ -z "$MISSING" ]; then
  ok "All schema fields in YamlKeys"
else
  fail "Missing in YamlKeys: $MISSING"
fi

# ─── 7. Studio hardcode check ───

step "Studio: no hardcoded schema values"
cd analytics-gen-studio/src
HARDCODE=$(grep -rn "'events'\|'shared_parameters'\|'dart'\|'plan'\|'csv'\|'snake_case'\|'No description'\|'lib/src/analytics'" \
  --include="*.ts" --include="*.tsx" \
  | grep -v "node_modules\|__tests__\|generated\|constants\|schemas/\|tab:\|case '\|TabId\|import \|\.d\.ts" \
  | grep -cv "selectedPath\.\|\.tab !==\|\.tab ===\|'events' ?\|outputs: Required\|tab: '\|id: '\|, 'events'" || true)
cd "$ROOT"
if [ "$HARDCODE" -le 0 ] 2>/dev/null; then
  ok "No hardcoded schema values"
else
  fail "$HARDCODE potential hardcoded values found in Studio"
fi

# ─── 8. Schema validation (schemas are valid JSON) ───

step "Schema files valid JSON"
SCHEMA_OK=true
for f in schema/*.json; do
  if ! node -e "JSON.parse(require('fs').readFileSync('$f','utf8'))" 2>/dev/null; then
    fail "$f is not valid JSON"
    SCHEMA_OK=false
  fi
done
if $SCHEMA_OK; then
  ok "All $(ls schema/*.json | wc -l | tr -d ' ') schema files valid"
fi

# ─── Summary ───

echo ""
echo -e "${CYAN}═══════════════════════════════════════${NC}"
if [ "$failed" -eq 0 ]; then
  echo -e "${GREEN}  All $passed checks passed ✓${NC}"
else
  echo -e "${YELLOW}  $passed passed, ${RED}$failed failed${NC}"
fi
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo ""

exit $failed
