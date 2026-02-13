#!/bin/bash

# PulseAssist Project Setup Script
# This script sets up the development environment

set -e

echo "🚀 Setting up PulseAssist development environment..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -n 1)"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Generate code (Hive, Mockito, etc.)
echo "🔨 Generating code..."
flutter pub run build_runner build --delete-conflicting-outputs

# Check for API configuration
if [ ! -f "lib/core/config/api_config.dart" ]; then
    echo "⚠️  API configuration not found!"
    echo "📝 Creating api_config.dart from example..."
    cp lib/core/config/api_config.example.dart lib/core/config/api_config.dart
    echo "⚠️  Please edit lib/core/config/api_config.dart and add your API keys"
fi

# Run static analysis
echo "🔍 Running static analysis..."
flutter analyze

# Run tests
echo "🧪 Running tests..."
flutter test

echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit lib/core/config/api_config.dart and add your API keys"
echo "2. Run 'flutter run' to start the app"
echo "3. Run 'make test' to run tests"
echo "4. Run 'make coverage' to generate coverage report"
