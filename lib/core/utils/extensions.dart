import 'package:intl/intl.dart';

/// Extension methods for String
extension StringExtensions on String {
  /// Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalize first letter of each word
  String capitalizeWords() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  /// Check if string is null or empty
  bool get isNullOrEmpty => isEmpty;

  /// Check if string is not null or empty
  bool get isNotNullOrEmpty => isNotEmpty;

  /// Remove all whitespace
  String removeWhitespace() {
    return replaceAll(RegExp(r'\s+'), '');
  }

  /// Truncate string to max length with ellipsis
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Convert to snake_case
  String toSnakeCase() {
    return replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    ).replaceFirst(RegExp(r'^_'), '');
  }

  /// Convert to camelCase
  String toCamelCase() {
    final words = split(RegExp(r'[_\s]+'));
    if (words.isEmpty) return this;
    return words.first.toLowerCase() +
        words.skip(1).map((word) => word.capitalize()).join();
  }

  /// Check if string contains only digits
  bool get isDigitsOnly => RegExp(r'^\d+$').hasMatch(this);

  /// Check if string contains only letters
  bool get isLettersOnly => RegExp(r'^[a-zA-Z]+$').hasMatch(this);
}

/// Extension methods for DateTime
extension DateTimeExtensions on DateTime {
  /// Format date as dd/MM/yyyy
  String toFormattedDate() {
    return DateFormat('dd/MM/yyyy').format(this);
  }

  /// Format time as HH:mm
  String toFormattedTime() {
    return DateFormat('HH:mm').format(this);
  }

  /// Format date and time as dd/MM/yyyy HH:mm
  String toFormattedDateTime() {
    return DateFormat('dd/MM/yyyy HH:mm').format(this);
  }

  /// Format date as full date (e.g., "Monday, 13 February 2026")
  String toFullDate({String locale = 'en'}) {
    return DateFormat('EEEE, dd MMMM yyyy', locale).format(this);
  }

  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Check if date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Get start of day (00:00:00)
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  /// Get end of day (23:59:59)
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }

  /// Check if date is in the past
  bool get isPast => isBefore(DateTime.now());

  /// Check if date is in the future
  bool get isFuture => isAfter(DateTime.now());

  /// Get relative time string (e.g., "2 hours ago", "in 3 days")
  String toRelativeTime({String locale = 'en'}) {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.isNegative) {
      // Future
      final futureDiff = difference.abs();
      if (futureDiff.inDays > 365) {
        return 'in ${(futureDiff.inDays / 365).floor()} years';
      } else if (futureDiff.inDays > 30) {
        return 'in ${(futureDiff.inDays / 30).floor()} months';
      } else if (futureDiff.inDays > 0) {
        return 'in ${futureDiff.inDays} days';
      } else if (futureDiff.inHours > 0) {
        return 'in ${futureDiff.inHours} hours';
      } else if (futureDiff.inMinutes > 0) {
        return 'in ${futureDiff.inMinutes} minutes';
      } else {
        return 'in a few seconds';
      }
    } else {
      // Past
      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()} years ago';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()} months ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} days ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hours ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minutes ago';
      } else {
        return 'just now';
      }
    }
  }
}

/// Extension methods for List
extension ListExtensions<T> on List<T> {
  /// Check if list is null or empty
  bool get isNullOrEmpty => isEmpty;

  /// Check if list is not null or empty
  bool get isNotNullOrEmpty => isNotEmpty;

  /// Get first element or null if empty
  T? get firstOrNull => isEmpty ? null : first;

  /// Get last element or null if empty
  T? get lastOrNull => isEmpty ? null : last;

  /// Safely get element at index or null
  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}

/// Extension methods for int
extension IntExtensions on int {
  /// Format as currency (Turkish Lira)
  String toTRY() {
    return '₺${NumberFormat('#,##0.00', 'tr_TR').format(this)}';
  }

  /// Format as currency (US Dollar)
  String toUSD() {
    return '\$${NumberFormat('#,##0.00', 'en_US').format(this)}';
  }

  /// Format with thousand separators
  String toFormatted() {
    return NumberFormat('#,##0', 'en_US').format(this);
  }
}

/// Extension methods for double
extension DoubleExtensions on double {
  /// Format as currency (Turkish Lira)
  String toTRY() {
    return '₺${NumberFormat('#,##0.00', 'tr_TR').format(this)}';
  }

  /// Format as currency (US Dollar)
  String toUSD() {
    return '\$${NumberFormat('#,##0.00', 'en_US').format(this)}';
  }

  /// Format with thousand separators and decimals
  String toFormatted({int decimals = 2}) {
    return NumberFormat('#,##0.${'0' * decimals}', 'en_US').format(this);
  }

  /// Round to specified decimal places
  double roundToDecimal(int decimals) {
    final mod = 10.0 * decimals;
    return (this * mod).round() / mod;
  }
}
