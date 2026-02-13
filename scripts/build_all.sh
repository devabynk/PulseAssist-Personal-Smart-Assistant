#!/bin/bash

# Build All Platforms Script
# Builds the app for all supported platforms

set -e

echo "🏗️  Building PulseAssist for all platforms..."

# Android APK
echo "📱 Building Android APK (Release)..."
flutter build apk --release

# Android App Bundle
echo "📦 Building Android App Bundle (Release)..."
flutter build appbundle --release

# iOS (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Building iOS (Release)..."
    flutter build ios --release --no-codesign
else
    echo "⏭️  Skipping iOS build (not on macOS)"
fi

# Web
echo "🌐 Building Web (Release)..."
flutter build web --release

# Linux (if on Linux)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "🐧 Building Linux (Release)..."
    flutter build linux --release
else
    echo "⏭️  Skipping Linux build (not on Linux)"
fi

echo "✅ Build complete!"
echo ""
echo "Build outputs:"
echo "  Android APK: build/app/outputs/flutter-apk/app-release.apk"
echo "  Android Bundle: build/app/outputs/bundle/release/app-release.aab"
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "  iOS: build/ios/iphoneos/Runner.app"
fi
echo "  Web: build/web/"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "  Linux: build/linux/x64/release/bundle/"
fi
