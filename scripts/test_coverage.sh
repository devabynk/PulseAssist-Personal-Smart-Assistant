#!/bin/bash

# Test Coverage Script
# Generates test coverage report for the project

set -e

echo "🧪 Running tests with coverage..."

# Remove old coverage data
rm -rf coverage

# Run tests with coverage
flutter test --coverage

# Check if lcov is installed
if ! command -v lcov &> /dev/null; then
    echo "⚠️  lcov is not installed. Install it to generate HTML reports."
    echo "   On Ubuntu/Debian: sudo apt-get install lcov"
    echo "   On macOS: brew install lcov"
    exit 0
fi

# Remove generated files from coverage
lcov --remove coverage/lcov.info \
    '**/*.g.dart' \
    '**/*.freezed.dart' \
    '**/l10n/*.dart' \
    '**/hive_registrar.g.dart' \
    -o coverage/lcov.info

# Generate HTML report
echo "📊 Generating HTML coverage report..."
genhtml coverage/lcov.info -o coverage/html

# Calculate coverage percentage
coverage_percent=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" | awk '{print $2}')

echo "✅ Coverage report generated!"
echo "📈 Coverage: $coverage_percent"
echo "📂 Open coverage/html/index.html to view the report"

# Check if coverage meets minimum threshold
threshold=70
current=$(echo $coverage_percent | sed 's/%//')
if (( $(echo "$current < $threshold" | bc -l) )); then
    echo "⚠️  Coverage is below $threshold% threshold!"
    exit 1
else
    echo "✅ Coverage meets $threshold% threshold"
fi
