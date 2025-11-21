#!/usr/bin/env bash
# Generates local lcov.info for coverage uploads.
# Run from repo root: ./tool/gen_coverage.sh
set -euo pipefail

echo "Running tests with coverage..."
dart pub get

dart test --coverage=coverage

echo "Formatting coverage to lcov..."
dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=.dart_tool/package_config.json --report-on=lib

if [ -f coverage/lcov.info ]; then
  echo "Coverage file created at coverage/lcov.info"
  echo "Generating HTML report..."
  genhtml coverage/lcov.info -o coverage/html
  echo "HTML report generated at coverage/html/index.html"
else
  echo "No coverage file created"
  exit 1
fi
