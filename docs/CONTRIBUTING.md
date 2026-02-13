# Contributing to PulseAssist

Thank you for your interest in contributing to PulseAssist! This document provides guidelines for contributing to the project.

## Getting Started

1. **Fork the repository**
2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/PulseAssist-Personal-Smart-Assistant.git
   cd PulseAssist-Personal-Smart-Assistant
   ```

3. **Set up the development environment**
   ```bash
   make setup
   ```

4. **Create a branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Workflow

### 1. Make Changes

- Follow the existing code style
- Write tests for new features
- Update documentation as needed

### 2. Run Tests

```bash
make test
make coverage
```

Ensure test coverage remains above 70%.

### 3. Run Static Analysis

```bash
make analyze
```

Fix any linting errors or warnings.

### 4. Format Code

```bash
make format
```

### 5. Commit Changes

Use conventional commit messages:

```
feat: add new alarm feature
fix: resolve notification bug
docs: update README
test: add unit tests for validators
refactor: improve error handling
style: format code
chore: update dependencies
```

### 6. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Create a pull request with:
- Clear description of changes
- Link to related issues
- Screenshots for UI changes
- Test results

## Code Style

### Dart Style Guide

Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style):

- Use `lowerCamelCase` for variables and functions
- Use `UpperCamelCase` for classes
- Use `lowercase_with_underscores` for file names
- Prefer single quotes for strings
- Use trailing commas for better formatting

### Project-Specific Guidelines

1. **File Organization**
   - Keep files under 500 lines
   - One class per file (except small helper classes)
   - Group related functionality

2. **Naming Conventions**
   - Screens: `*_screen.dart`
   - Providers: `*_provider.dart`
   - Services: `*_service.dart`
   - Models: `*.dart` (singular)
   - Tests: `*_test.dart`

3. **Documentation**
   - Add doc comments for public APIs
   - Explain complex logic with inline comments
   - Update README for new features

4. **Error Handling**
   - Use custom exceptions from `core/error/`
   - Always handle errors gracefully
   - Log errors appropriately

5. **Testing**
   - Write tests for new features
   - Maintain >70% coverage
   - Test edge cases

## Pull Request Process

1. **Update Documentation** - Update README, docs, and inline comments
2. **Add Tests** - Ensure new code is tested
3. **Run All Checks** - Tests, linting, formatting
4. **Request Review** - Tag relevant reviewers
5. **Address Feedback** - Make requested changes
6. **Squash Commits** - Clean up commit history before merge

## Reporting Issues

### Bug Reports

Include:
- Clear description of the bug
- Steps to reproduce
- Expected vs actual behavior
- Screenshots/videos if applicable
- Device/OS information
- App version

### Feature Requests

Include:
- Clear description of the feature
- Use case and benefits
- Proposed implementation (optional)
- Mockups/wireframes (optional)

## Code Review Guidelines

### For Reviewers

- Be constructive and respectful
- Focus on code quality, not style preferences
- Test the changes locally
- Approve only when satisfied

### For Contributors

- Respond to feedback promptly
- Ask questions if unclear
- Don't take feedback personally
- Learn from the review process

## Development Tools

### Makefile Commands

```bash
make help          # Show all commands
make setup         # Initial setup
make test          # Run tests
make coverage      # Generate coverage
make analyze       # Run static analysis
make build-android # Build Android APK
make run-dev       # Run in dev mode
```

### Scripts

- `scripts/setup.sh` - Project setup
- `scripts/test_coverage.sh` - Coverage report
- `scripts/build_all.sh` - Build all platforms
- `scripts/clean_build.sh` - Clean build

## Environment Setup

### API Keys

1. Copy `lib/core/config/api_config.example.dart` to `lib/core/config/api_config.dart`
2. Add your API keys
3. Never commit `api_config.dart`

### Running Different Environments

```bash
make run-dev       # Development
make run-prod      # Production
```

## Questions?

- Open an issue for questions
- Join our community discussions
- Check existing documentation

## License

By contributing, you agree that your contributions will be licensed under the GNU GPLv3 License.
