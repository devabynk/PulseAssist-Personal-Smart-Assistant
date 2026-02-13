# Testing Guide

## Overview

PulseAssist uses a comprehensive testing strategy with unit tests, widget tests, and integration tests to ensure code quality and reliability.

## Test Structure

```
test/
├── helpers/              # Test utilities
│   ├── pump_app.dart    # Widget test helpers
│   ├── mock_factories.dart  # Mock data factories
│   └── fixtures.dart    # Test fixtures
├── unit/                # Unit tests
│   ├── core/           # Core functionality tests
│   └── ...
├── widget/             # Widget tests
│   └── ...
├── integration/        # Integration tests
│   └── ...
└── fixtures/           # Test data
    ├── json/          # JSON fixtures
    └── ...

integration_test/       # Integration tests (separate)
```

## Running Tests

### All Tests
```bash
make test
# or
flutter test
```

### Specific Test File
```bash
flutter test test/unit/core/config_test.dart
```

### With Coverage
```bash
make coverage
# or
./scripts/test_coverage.sh
```

### Integration Tests
```bash
flutter test integration_test/
```

## Writing Tests

### Unit Tests

Test individual functions and classes in isolation:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_assistant/core/utils/validators.dart';

void main() {
  group('Validators Tests', () {
    test('should validate email', () {
      expect(Validators.isValidEmail('test@example.com'), true);
      expect(Validators.isValidEmail('invalid'), false);
    });
  });
}
```

### Widget Tests

Test UI components:

```dart
import 'package:flutter_test/flutter_test.dart';
import '../helpers/pump_app.dart';

void main() {
  testWidgets('MyWidget should display title', (tester) async {
    await pumpApp(tester, MyWidget());
    
    expect(find.text('Title'), findsOneWidget);
  });
}
```

### Integration Tests

Test complete user flows:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Create alarm flow', (tester) async {
    // Launch app
    app.main();
    await tester.pumpAndSettle();

    // Navigate to alarms
    await tester.tap(find.text('Alarms'));
    await tester.pumpAndSettle();

    // Create alarm
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Verify alarm created
    expect(find.text('New Alarm'), findsOneWidget);
  });
}
```

## Test Helpers

### pumpApp

Helper to pump widgets with all necessary providers:

```dart
await pumpApp(
  tester,
  MyWidget(),
  providers: [
    ChangeNotifierProvider(create: (_) => MyProvider()),
  ],
);
```

### MockDataFactory

Create mock data for testing:

```dart
final mockAlarm = MockDataFactory.createMockAlarm(
  title: 'Test Alarm',
  dateTime: DateTime.now(),
);

final mockAlarms = MockDataFactory.createMockAlarms(5);
```

### FixtureReader

Load test fixtures:

```dart
final jsonData = FixtureReader.jsonFixture('alarm.json');
final textData = FixtureReader.fixture('test_data.txt');
```

## Mocking

### Using Mockito

```dart
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([DatabaseService, AiManager])
void main() {
  late MockDatabaseService mockDb;

  setUp(() {
    mockDb = MockDatabaseService();
    when(mockDb.getAlarms()).thenAnswer((_) async => []);
  });

  test('should fetch alarms', () async {
    final alarms = await mockDb.getAlarms();
    expect(alarms, isEmpty);
    verify(mockDb.getAlarms()).called(1);
  });
}
```

### Using Mocktail

```dart
import 'package:mocktail/mocktail.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late MockDatabaseService mockDb;

  setUp(() {
    mockDb = MockDatabaseService();
    when(() => mockDb.getAlarms()).thenAnswer((_) async => []);
  });

  test('should fetch alarms', () async {
    final alarms = await mockDb.getAlarms();
    expect(alarms, isEmpty);
    verify(() => mockDb.getAlarms()).called(1);
  });
}
```

## Coverage Goals

- **Overall Coverage**: >70%
- **Core Utilities**: >90%
- **Business Logic**: >80%
- **UI Components**: >60%

## Best Practices

1. **Test Naming** - Use descriptive test names
2. **Arrange-Act-Assert** - Follow AAA pattern
3. **One Assertion** - Test one thing per test
4. **Mock External Dependencies** - Don't test external services
5. **Test Edge Cases** - Test boundary conditions
6. **Keep Tests Fast** - Unit tests should run in milliseconds
7. **Avoid Test Interdependence** - Tests should be independent

## Continuous Integration

Tests run automatically on:
- Every commit (pre-commit hook)
- Pull requests
- Main branch merges

## Troubleshooting

### Tests Failing Locally

```bash
# Clean and rebuild
make clean
flutter pub get
flutter test
```

### Coverage Not Generating

```bash
# Install lcov
sudo apt-get install lcov  # Ubuntu/Debian
brew install lcov          # macOS
```

### Flaky Tests

- Use `pumpAndSettle()` instead of `pump()`
- Add delays for animations: `await tester.pump(Duration(seconds: 1))`
- Mock time-dependent code
