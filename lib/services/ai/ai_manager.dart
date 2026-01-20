import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'ai_provider.dart';
import 'groq_provider.dart';

/// Unified AI Manager with internet connectivity check
/// Uses Groq AI (Llama 3.1 8B) for intelligent responses
class AiManager {
  static final AiManager instance = AiManager._init();
  
  final GroqProvider _groq = GroqProvider();
  final Connectivity _connectivity = Connectivity();
  
  bool _hasInternet = true;
  
  AiManager._init();
  
  /// Check if AI provider is available
  bool get isAvailable => _groq.isAvailable;
  
  /// Get the currently active provider name
  String? get activeProvider => _groq.isAvailable ? 'Groq' : null;
  
  /// Check internet connectivity using multiple methods
  Future<bool> checkConnectivity() async {
    try {
      // First check with connectivity_plus
      final result = await _connectivity.checkConnectivity();
      if (result.contains(ConnectivityResult.none)) {
        _hasInternet = false;
        return false;
      }
      
      // Then verify with actual HTTP request (more reliable)
      try {
        final httpResult = await InternetAddress.lookup('api.groq.com')
            .timeout(const Duration(seconds: 3));
        _hasInternet = httpResult.isNotEmpty && httpResult[0].rawAddress.isNotEmpty;
      } catch (e) {
        // DNS lookup failed, try google as backup
        try {
          final googleResult = await InternetAddress.lookup('google.com')
              .timeout(const Duration(seconds: 2));
          _hasInternet = googleResult.isNotEmpty && googleResult[0].rawAddress.isNotEmpty;
        } catch (_) {
          _hasInternet = false;
        }
      }
      
      return _hasInternet;
    } catch (e) {
      debugPrint('Connectivity check failed: $e');
      // On error, assume we have internet and let the API call fail if not
      _hasInternet = true;
      return true;
    }
  }
  
  /// Initialize all providers
  Future<void> initialize() async {
    // Initialize Groq provider first (doesn't need network)
    await _groq.initialize();
    
    // Check internet connectivity
    await checkConnectivity();
    
    debugPrint('AI Manager initialized:');
    debugPrint('  - Groq: ${_groq.isAvailable ? "Ready" : "Not available"}');
    debugPrint('  - Internet: ${_hasInternet ? "Connected" : "No connection"}');
  }
  
  /// Set Groq API key dynamically
  Future<bool> setApiKey(String key) async {
    return await _groq.setApiKey(key);
  }
  
  /// Send a message with automatic connectivity handling
  /// Throws exception if AI is unavailable - let caller handle fallback
  Future<String> chat({
    required String message,
    required bool isTurkish,
    String? userName,
    List<ChatMessage>? conversationHistory,
    String? attachmentPath,
    String? attachmentType,
    String? weatherContext,
  }) async {
    // Check internet connectivity before making AI call
    final hasNetwork = await checkConnectivity();
    
    if (!hasNetwork) {
      debugPrint('No internet connection, throwing exception for fallback');
      throw Exception('No internet connection');
    }
    
    if (!_groq.isAvailable) {
      // Try to reinitialize
      await _groq.initialize();
      if (!_groq.isAvailable) {
        debugPrint('Groq not available after reinit, throwing exception for fallback');
        throw Exception('Groq provider not available');
      }
    }
    
    // Try Groq
    final response = await _groq.chat(
      message: message,
      isTurkish: isTurkish,
      userName: userName,
      conversationHistory: conversationHistory,
      attachmentPath: attachmentPath,
      attachmentType: attachmentType,
      weatherContext: weatherContext,
    );
    
    if (response != null && response.isNotEmpty) {
      debugPrint('AI Response from Groq (Llama 3.1)');
      return response;
    }
    
    // Groq returned null - throw exception for fallback
    debugPrint('Groq returned null, throwing exception for fallback');
    throw Exception('AI service returned no response');
  }
  
  /// Clear all provider sessions
  void clearAllSessions() {
    _groq.clearSession();
  }
  
  /// Get status of all providers
  Map<String, dynamic> getProvidersStatus() {
    return {
      'Groq': _groq.isAvailable,
      'Internet': _hasInternet,
    };
  }
}
