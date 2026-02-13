import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../config/app_config.dart';

/// Application logger wrapper
class AppLogger {
  AppLogger._();

  static final AppLogger _instance = AppLogger._();
  static AppLogger get instance => _instance;

  late Logger _logger;
  bool _initialized = false;

  /// Initialize logger
  void initialize({AppConfig? config}) {
    if (_initialized) return;

    final enableLogging = config?.enableLogging ?? kDebugMode;

    _logger = Logger(
      filter: ProductionFilter(),
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      level: enableLogging ? Level.debug : Level.error,
    );

    _initialized = true;
  }

  /// Log debug message
  void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (!_initialized) initialize();
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log info message
  void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (!_initialized) initialize();
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning message
  void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (!_initialized) initialize();
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error message
  void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (!_initialized) initialize();
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal message
  void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (!_initialized) initialize();
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Log trace message
  void trace(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (!_initialized) initialize();
    _logger.t(message, error: error, stackTrace: stackTrace);
  }
}

/// Production filter to control log levels
class ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return kDebugMode || event.level.index >= Level.warning.index;
  }
}
