/// Input validation utilities
library;

class Validators {
  Validators._();

  /// Validate email address
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate phone number (basic validation)
  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^\+?[\d\s-()]{10,}$');
    return phoneRegex.hasMatch(phone);
  }

  /// Validate URL
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Validate non-empty string
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  /// Validate string length
  static bool hasMinLength(String value, int minLength) {
    return value.length >= minLength;
  }

  /// Validate string max length
  static bool hasMaxLength(String value, int maxLength) {
    return value.length <= maxLength;
  }

  /// Validate string length range
  static bool hasLengthBetween(String value, int min, int max) {
    return value.length >= min && value.length <= max;
  }

  /// Validate numeric string
  static bool isNumeric(String value) {
    return double.tryParse(value) != null;
  }

  /// Validate integer string
  static bool isInteger(String value) {
    return int.tryParse(value) != null;
  }

  /// Validate alphanumeric string
  static bool isAlphanumeric(String value) {
    final alphanumericRegex = RegExp(r'^[a-zA-Z0-9]+$');
    return alphanumericRegex.hasMatch(value);
  }

  /// Validate date string (dd/MM/yyyy format)
  static bool isValidDate(String date) {
    final dateRegex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!dateRegex.hasMatch(date)) return false;

    try {
      final parts = date.split('/');
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      final parsedDate = DateTime(year, month, day);
      return parsedDate.day == day &&
          parsedDate.month == month &&
          parsedDate.year == year;
    } catch (e) {
      return false;
    }
  }

  /// Validate time string (HH:mm format)
  static bool isValidTime(String time) {
    final timeRegex = RegExp(r'^\d{2}:\d{2}$');
    if (!timeRegex.hasMatch(time)) return false;

    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;
    } catch (e) {
      return false;
    }
  }
}
