/// Custom exceptions for the application
library;

/// Base exception class
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(this.message, {this.code, this.details});

  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Server exception - API or backend errors
class ServerException extends AppException {
  const ServerException(super.message, {super.code, super.details});

  @override
  String toString() => 'ServerException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Cache exception - Local storage errors
class CacheException extends AppException {
  const CacheException(super.message, {super.code, super.details});

  @override
  String toString() => 'CacheException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Network exception - Connectivity issues
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.details});

  @override
  String toString() => 'NetworkException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Validation exception - Input validation errors
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.details});

  @override
  String toString() => 'ValidationException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Authentication exception - Auth errors
class AuthenticationException extends AppException {
  const AuthenticationException(super.message, {super.code, super.details});

  @override
  String toString() => 'AuthenticationException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Permission exception - Permission denied errors
class PermissionException extends AppException {
  const PermissionException(super.message, {super.code, super.details});

  @override
  String toString() => 'PermissionException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Timeout exception - Request timeout errors
class TimeoutException extends AppException {
  const TimeoutException(super.message, {super.code, super.details});

  @override
  String toString() => 'TimeoutException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Not found exception - Resource not found
class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.code, super.details});

  @override
  String toString() => 'NotFoundException: $message${code != null ? ' (Code: $code)' : ''}';
}
