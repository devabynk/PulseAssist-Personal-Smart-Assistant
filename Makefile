# PulseAssist Makefile
# Common development commands

.PHONY: help setup clean test coverage analyze build-android build-ios build-web run

# Default target
help:
	@echo "PulseAssist Development Commands"
	@echo "================================="
	@echo "make setup          - Initial project setup"
	@echo "make clean          - Clean build artifacts"
	@echo "make test           - Run all tests"
	@echo "make coverage       - Generate test coverage report"
	@echo "make analyze        - Run static analysis"
	@echo "make build-android  - Build Android APK"
	@echo "make build-bundle   - Build Android App Bundle"
	@echo "make build-ios      - Build iOS app"
	@echo "make build-web      - Build web app"
	@echo "make build-all      - Build for all platforms"
	@echo "make run            - Run the app in debug mode"
	@echo "make run-dev        - Run with development environment"
	@echo "make run-prod       - Run with production environment"

# Initial setup
setup:
	@chmod +x scripts/*.sh
	@./scripts/setup.sh

# Clean build artifacts
clean:
	@./scripts/clean_build.sh

# Run tests
test:
	@flutter test

# Generate coverage report
coverage:
	@./scripts/test_coverage.sh

# Run static analysis
analyze:
	@flutter analyze

# Build Android APK
build-android:
	@flutter build apk --release

# Build Android App Bundle
build-bundle:
	@flutter build appbundle --release

# Build iOS
build-ios:
	@flutter build ios --release --no-codesign

# Build Web
build-web:
	@flutter build web --release

# Build all platforms
build-all:
	@./scripts/build_all.sh

# Run app in debug mode
run:
	@flutter run

# Run with development environment
run-dev:
	@flutter run --dart-define=ENV=development

# Run with production environment
run-prod:
	@flutter run --dart-define=ENV=production

# Get dependencies
deps:
	@flutter pub get

# Generate code
generate:
	@flutter pub run build_runner build --delete-conflicting-outputs

# Format code
format:
	@flutter format lib/ test/

# Fix lint issues
fix:
	@dart fix --apply
