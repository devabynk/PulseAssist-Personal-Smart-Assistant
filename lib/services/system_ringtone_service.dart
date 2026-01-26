import 'package:flutter/services.dart';

class SystemRingtone {
  final String title;
  final String uri;
  final bool isDefault;

  SystemRingtone({
    required this.title,
    required this.uri,
    this.isDefault = false,
  });

  factory SystemRingtone.fromMap(Map<dynamic, dynamic> map) {
    return SystemRingtone(
      title: map['title'] as String,
      uri: map['uri'] as String,
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }
}

class SystemRingtoneService {
  static const MethodChannel _channel = MethodChannel('com.abynk.smart_assistant/ringtones');

  /// Fetch list of system ringtones (Android)
  /// Returns empty list on iOS (access restricted)
  static Future<List<SystemRingtone>> getRingtones() async {
    try {
      final List<dynamic>? result = await _channel.invokeMethod('getRingtones');
      if (result == null) return [];
      
      return result.map((e) => SystemRingtone.fromMap(e as Map)).toList();
    } on PlatformException catch (e) {
      print('Failed to get ringtones: ${e.message}');
      return [];
    }
  }

  /// Play ringtone for preview
  static Future<void> playRingtone(String uri) async {
    try {
      await _channel.invokeMethod('playRingtone', {'uri': uri});
    } on PlatformException catch (e) {
      print('Failed to play ringtone: ${e.message}');
    }
  }

  /// Stop preview
  static Future<void> stopRingtone() async {
    try {
      await _channel.invokeMethod('stopRingtone');
    } on PlatformException catch (e) {
      print('Failed to stop ringtone: ${e.message}');
    }
  }
}
