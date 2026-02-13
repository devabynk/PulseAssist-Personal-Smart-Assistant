import 'package:flutter/foundation.dart';

import 'exceptions.dart';
import 'failures.dart';

/// Global error handler for the application
class ErrorHandler {
  ErrorHandler._();

  static final ErrorHandler _instance = ErrorHandler._();
  static ErrorHandler get instance => _instance;

  /// Initialize error handler
  void initialize() {
    // Set up global error handlers
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _logError(details.exception, details.stack);
    };

    // Handle errors outside Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      _logError(error, stack);
      return true;
    };
  }

  /// Convert exceptions to failures
  Failure handleException(Object exception) {
    if (exception is ServerException) {
      return ServerFailure(exception.message, code: exception.code, details: exception.details);
    } else if (exception is CacheException) {
      return CacheFailure(exception.message, code: exception.code, details: exception.details);
    } else if (exception is NetworkException) {
      return NetworkFailure(exception.message, code: exception.code, details: exception.details);
    } else if (exception is ValidationException) {
      return ValidationFailure(exception.message, code: exception.code, details: exception.details);
    } else if (exception is AuthenticationException) {
      return AuthenticationFailure(exception.message, code: exception.code, details: exception.details);
    } else if (exception is PermissionException) {
      return PermissionFailure(exception.message, code: exception.code, details: exception.details);
    } else if (exception is TimeoutException) {
      return TimeoutFailure(exception.message, code: exception.code, details: exception.details);
    } else if (exception is NotFoundException) {
      return NotFoundFailure(exception.message, code: exception.code, details: exception.details);
    } else {
      return UnknownFailure(exception.toString());
    }
  }

  /// Log error
  void _logError(Object error, StackTrace? stackTrace) {
    if (kDebugMode) {
      debugPrint('Error: $error');
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }
    // TODO: Send to crash reporting service in production
  }
}

