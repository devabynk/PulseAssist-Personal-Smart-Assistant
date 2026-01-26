import 'dart:async';
import 'package:flutter/foundation.dart';

/// Type of failure to determine if rotation is needed
enum FailureType {
  rateLimit, // 429: Rotate immediately
  unauthorized, // 401: Rotate immediately (key invalid)
  serverError, // 500+: Retry same key, then rotate
  connection, // Network: Retry same key, then rotate if persistent
  unknown,
}

/// Generic manager for cycling through a list of API keys
class KeyManager {
  final List<String> _keys;
  final String serviceName;
  
  int _currentIndex = 0;
  
  // Track failed keys with cooldown
  final Map<String, DateTime> _failedKeys = {};
  
  // Cooldown duration for rate-limited keys
  static const Duration _cooldown = Duration(minutes: 5);

  KeyManager(List<String> keys, {required this.serviceName}) 
      : _keys = List.unmodifiable(keys) {
    if (_keys.isEmpty) {
      debugPrint('⚠️ KeyManager for $serviceName initialized with empty key list!');
    }
  }

  /// Get current key
  String get currentKey {
    if (_keys.isEmpty) return '';
    return _keys[_currentIndex];
  }

  /// Rotate to next available key
  String rotate() {
    if (_keys.isEmpty) return '';
    if (_keys.length == 1) return _keys[0];

    final start = _currentIndex;
    int next = (_currentIndex + 1) % _keys.length;

    // Try to find a non-failed key
    while (next != start) {
      final key = _keys[next];
      if (!_isKeyInCooldown(key)) {
        _currentIndex = next;
        debugPrint('🔄 $serviceName: Rotated to key index $_currentIndex');
        return key;
      }
      next = (next + 1) % _keys.length;
    }

    // If all keys are failed, just force rotate to next one to try anyway
    _currentIndex = (_currentIndex + 1) % _keys.length;
    debugPrint('⚠️ $serviceName: All keys in cooldown, forcing rotation to $_currentIndex');
    return _keys[_currentIndex];
  }

  bool _isKeyInCooldown(String key) {
    if (!_failedKeys.containsKey(key)) return false;
    
    if (DateTime.now().isAfter(_failedKeys[key]!)) {
      _failedKeys.remove(key); // Cooldown expired
      return false;
    }
    return true;
  }

  /// Report a failure on the current key
  void reportFailure(FailureType type) {
    if (_keys.isEmpty) return;
    
    final key = currentKey;
    debugPrint('❌ $serviceName: Failure reported ($type) on key ...${key.substring(key.length > 5 ? key.length - 5 : 0)}');

    if (type == FailureType.rateLimit || type == FailureType.unauthorized) {
      _failedKeys[key] = DateTime.now().add(_cooldown);
      rotate();
    } 
    // For connection/server errors, we might want to rotate only after N failures, 
    // but for simplicity, we provide a rotate() method to be called manually by user if needed,
    // or we can auto-rotate here.
    // Let's auto-rotate for server error 500 too as it might be account related in some APIs.
    else if (type == FailureType.serverError) {
      rotate();
    }
  }

  /// Execute an API call with automatic failover
  Future<T> executeWithRetry<T>(
    Future<T> Function(String apiKey) action, {
    int maxAttempts = 3,
  }) async {
    int attempts = 0;
    
    // We try at least as many times as we have keys, or maxAttempts, whichever is greater (capped reasonable)
    final effectiveMax = _keys.length > maxAttempts ? _keys.length : maxAttempts;

    while (attempts < effectiveMax) {
      final key = currentKey;
      try {
        attempts++;
        return await action(key);
      } catch (e) {
        final errorStr = e.toString().toLowerCase();
        FailureType type = FailureType.unknown;

        // Auto-detect failure type from standard HTTP error conventions
        if (errorStr.contains('429') || errorStr.contains('rate limit')) {
          type = FailureType.rateLimit;
        } else if (errorStr.contains('401') || errorStr.contains('403') || errorStr.contains('unauthorized')) {
          type = FailureType.unauthorized;
        } else if (errorStr.contains('500') || errorStr.contains('502') || errorStr.contains('503')) {
          type = FailureType.serverError;
        } else if (errorStr.contains('socket') || errorStr.contains('timeout') || errorStr.contains('connection')) {
          type = FailureType.connection;
        }

        // If it's the last attempt, rethrow
        if (attempts >= effectiveMax) rethrow;

        // Report failure and rotate if needed
        reportFailure(type);
        
        // If connection error, wait a bit before retry
        if (type == FailureType.connection) {
             await Future.delayed(const Duration(seconds: 1));
        }
      }
    }
    throw Exception('$serviceName: All attempts failed.');
  }
}
