#!/bin/bash

# Clean Build Script
# Performs a clean build of the project

set -e

echo "🧹 Cleaning build artifacts..."

# Flutter clean
flutter clean

# Remove generated files
echo "🗑️  Removing generated files..."
find . -name "*.g.dart" -type f -delete
find . -name "*.freezed.dart" -type f -delete
find . -name "*.mocks.dart" -type f -delete

# Remove build directories
rm -rf build/
rm -rf .dart_tool/

echo "📦 Getting dependencies..."
flutter pub get

echo "🔨 Generating code..."
flutter pub run build_runner build --delete-conflicting-outputs

echo "✅ Clean build complete!"
echo "Run 'flutter run' to start the app"
