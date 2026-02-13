import 'package:flutter_test/flutter_test.dart';
import 'package:smart_assistant/core/utils/validators.dart';

void main() {
  group('Validators Tests', () {
    group('Email Validation', () {
      test('should validate correct email addresses', () {
        expect(Validators.isValidEmail('test@example.com'), true);
        expect(Validators.isValidEmail('user.name@domain.co.uk'), true);
        expect(Validators.isValidEmail('user+tag@example.com'), true);
      });

      test('should reject invalid email addresses', () {
        expect(Validators.isValidEmail('invalid'), false);
        expect(Validators.isValidEmail('@example.com'), false);
        expect(Validators.isValidEmail('user@'), false);
        expect(Validators.isValidEmail('user @example.com'), false);
      });
    });

    group('Phone Validation', () {
      test('should validate correct phone numbers', () {
        expect(Validators.isValidPhone('+905551234567'), true);
        expect(Validators.isValidPhone('05551234567'), true);
        expect(Validators.isValidPhone('+1 (555) 123-4567'), true);
      });

      test('should reject invalid phone numbers', () {
        expect(Validators.isValidPhone('123'), false);
        expect(Validators.isValidPhone('abc'), false);
      });
    });

    group('URL Validation', () {
      test('should validate correct URLs', () {
        expect(Validators.isValidUrl('https://example.com'), true);
        expect(Validators.isValidUrl('http://example.com'), true);
        expect(Validators.isValidUrl('https://example.com/path'), true);
      });

      test('should reject invalid URLs', () {
        expect(Validators.isValidUrl('example.com'), false);
        expect(Validators.isValidUrl('ftp://example.com'), false);
        expect(Validators.isValidUrl('not a url'), false);
      });
    });

    group('String Validation', () {
      test('should validate non-empty strings', () {
        expect(Validators.isNotEmpty('test'), true);
        expect(Validators.isNotEmpty('  test  '), true);
      });

      test('should reject empty strings', () {
        expect(Validators.isNotEmpty(''), false);
        expect(Validators.isNotEmpty('   '), false);
        expect(Validators.isNotEmpty(null), false);
      });

      test('should validate string length', () {
        expect(Validators.hasMinLength('test', 3), true);
        expect(Validators.hasMinLength('test', 4), true);
        expect(Validators.hasMinLength('test', 5), false);

        expect(Validators.hasMaxLength('test', 5), true);
        expect(Validators.hasMaxLength('test', 4), true);
        expect(Validators.hasMaxLength('test', 3), false);

        expect(Validators.hasLengthBetween('test', 3, 5), true);
        expect(Validators.hasLengthBetween('test', 4, 4), true);
        expect(Validators.hasLengthBetween('test', 5, 10), false);
      });
    });

    group('Numeric Validation', () {
      test('should validate numeric strings', () {
        expect(Validators.isNumeric('123'), true);
        expect(Validators.isNumeric('123.45'), true);
        expect(Validators.isNumeric('-123'), true);
      });

      test('should reject non-numeric strings', () {
        expect(Validators.isNumeric('abc'), false);
        expect(Validators.isNumeric('12a3'), false);
      });

      test('should validate integer strings', () {
        expect(Validators.isInteger('123'), true);
        expect(Validators.isInteger('-123'), true);
      });

      test('should reject non-integer strings', () {
        expect(Validators.isInteger('123.45'), false);
        expect(Validators.isInteger('abc'), false);
      });
    });

    group('Alphanumeric Validation', () {
      test('should validate alphanumeric strings', () {
        expect(Validators.isAlphanumeric('abc123'), true);
        expect(Validators.isAlphanumeric('ABC'), true);
        expect(Validators.isAlphanumeric('123'), true);
      });

      test('should reject non-alphanumeric strings', () {
        expect(Validators.isAlphanumeric('abc-123'), false);
        expect(Validators.isAlphanumeric('abc 123'), false);
        expect(Validators.isAlphanumeric('abc@123'), false);
      });
    });

    group('Date Validation', () {
      test('should validate correct date strings', () {
        expect(Validators.isValidDate('13/02/2026'), true);
        expect(Validators.isValidDate('01/01/2000'), true);
        expect(Validators.isValidDate('31/12/2099'), true);
      });

      test('should reject invalid date strings', () {
        expect(Validators.isValidDate('32/01/2026'), false);
        expect(Validators.isValidDate('13/13/2026'), false);
        expect(Validators.isValidDate('2026-02-13'), false);
        expect(Validators.isValidDate('invalid'), false);
      });
    });

    group('Time Validation', () {
      test('should validate correct time strings', () {
        expect(Validators.isValidTime('15:30'), true);
        expect(Validators.isValidTime('00:00'), true);
        expect(Validators.isValidTime('23:59'), true);
      });

      test('should reject invalid time strings', () {
        expect(Validators.isValidTime('24:00'), false);
        expect(Validators.isValidTime('15:60'), false);
        expect(Validators.isValidTime('3:30'), false);
        expect(Validators.isValidTime('invalid'), false);
      });
    });
  });
}
