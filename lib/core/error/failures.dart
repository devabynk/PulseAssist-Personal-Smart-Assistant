import 'package:equatable/equatable.dart';

/// Base failure class for error handling
abstract class Failure extends Equatable {
  final String message;
  final String? code;
  final dynamic details;

  const Failure(this.message, {this.code, this.details});

  @override
  List<Object?> get props => [message, code, details];

  @override
  String toString() => 'Failure: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Server failure - API or backend errors
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code, super.details});

  @override
  String toString() => 'ServerFailure: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Cache failure - Local storage errors
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code, super.details});

  @override
  String toString() => 'CacheFailure: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Network failure - Connectivity issues
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code, super.details});

  @override
  String toString() => 'NetworkFailure: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Validation failure - Input validation errors
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code, super.details});

  @override
  String toString() => 'ValidationFailure: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Authentication failure - Auth errors
class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message, {super.code, super.details});

  @override
  String toString() => 'AuthenticationFailure: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Permission failure - Permission denied errors
class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.code, super.details});

  @override
  String toString() => 'PermissionFailure: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Timeout failure - Request timeout errors
class TimeoutFailure extends Failure {
  const TimeoutFailure(super.message, {super.code, super.details});

  @override
  String toString() => 'TimeoutFailure: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Not found failure - Resource not found
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.code, super.details});

  @override
  String toString() => 'NotFoundFailure: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Unknown failure - Unexpected errors
class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.code, super.details});

  @override
  String toString() => 'UnknownFailure: $message${code != null ? ' (Code: $code)' : ''}';
}
