import 'package:flutter_test/flutter_test.dart';
import 'package:smart_assistant/core/utils/extensions.dart';

void main() {
  group('String Extensions Tests', () {
    test('capitalize should capitalize first letter', () {
      expect('hello'.capitalize(), 'Hello');
      expect('HELLO'.capitalize(), 'HELLO');
      expect(''.capitalize(), '');
    });

    test('capitalizeWords should capitalize each word', () {
      expect('hello world'.capitalizeWords(), 'Hello World');
      expect('test case'.capitalizeWords(), 'Test Case');
    });

    test('truncate should truncate long strings', () {
      expect('hello world'.truncate(8), 'hello...');
      expect('short'.truncate(10), 'short');
    });

    test('toSnakeCase should convert to snake_case', () {
      expect('HelloWorld'.toSnakeCase(), 'hello_world');
      expect('testCase'.toSnakeCase(), 'test_case');
    });

    test('toCamelCase should convert to camelCase', () {
      expect('hello_world'.toCamelCase(), 'helloWorld');
      expect('test_case'.toCamelCase(), 'testCase');
    });

    test('isDigitsOnly should check for digits', () {
      expect('123'.isDigitsOnly, true);
      expect('12a3'.isDigitsOnly, false);
      expect(''.isDigitsOnly, false);
    });

    test('isLettersOnly should check for letters', () {
      expect('abc'.isLettersOnly, true);
      expect('ab1c'.isLettersOnly, false);
      expect(''.isLettersOnly, false);
    });
  });

  group('DateTime Extensions Tests', () {
    final testDate = DateTime(2026, 2, 13, 15, 30);

    test('toFormattedDate should format date', () {
      expect(testDate.toFormattedDate(), '13/02/2026');
    });

    test('toFormattedTime should format time', () {
      expect(testDate.toFormattedTime(), '15:30');
    });

    test('toFormattedDateTime should format date and time', () {
      expect(testDate.toFormattedDateTime(), '13/02/2026 15:30');
    });

    test('isToday should check if date is today', () {
      expect(DateTime.now().isToday, true);
      expect(DateTime.now().subtract(const Duration(days: 1)).isToday, false);
    });

    test('isYesterday should check if date is yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(yesterday.isYesterday, true);
      expect(DateTime.now().isYesterday, false);
    });

    test('isTomorrow should check if date is tomorrow', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(tomorrow.isTomorrow, true);
      expect(DateTime.now().isTomorrow, false);
    });

    test('startOfDay should return start of day', () {
      final start = testDate.startOfDay;
      expect(start.hour, 0);
      expect(start.minute, 0);
      expect(start.second, 0);
    });

    test('endOfDay should return end of day', () {
      final end = testDate.endOfDay;
      expect(end.hour, 23);
      expect(end.minute, 59);
      expect(end.second, 59);
    });

    test('isPast should check if date is in the past', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      expect(past.isPast, true);
      expect(DateTime.now().add(const Duration(days: 1)).isPast, false);
    });

    test('isFuture should check if date is in the future', () {
      final future = DateTime.now().add(const Duration(days: 1));
      expect(future.isFuture, true);
      expect(DateTime.now().subtract(const Duration(days: 1)).isFuture, false);
    });
  });

  group('List Extensions Tests', () {
    test('firstOrNull should return first element or null', () {
      expect([1, 2, 3].firstOrNull, 1);
      expect(<int>[].firstOrNull, null);
    });

    test('lastOrNull should return last element or null', () {
      expect([1, 2, 3].lastOrNull, 3);
      expect(<int>[].lastOrNull, null);
    });

    test('elementAtOrNull should return element at index or null', () {
      expect([1, 2, 3].elementAtOrNull(1), 2);
      expect([1, 2, 3].elementAtOrNull(5), null);
      expect([1, 2, 3].elementAtOrNull(-1), null);
    });
  });

  group('Int Extensions Tests', () {
    test('toFormatted should format with thousand separators', () {
      expect(1000.toFormatted(), '1,000');
      expect(1000000.toFormatted(), '1,000,000');
    });
  });

  group('Double Extensions Tests', () {
    test('toFormatted should format with decimals', () {
      expect(1234.56.toFormatted(), '1,234.56');
      expect(1234.56.toFormatted(decimals: 3), '1,234.560');
    });

    test('roundToDecimal should round to decimal places', () {
      expect(1.2345.roundToDecimal(2), 1.23);
      expect(1.2365.roundToDecimal(2), 1.24);
    });
  });
}
