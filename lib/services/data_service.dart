import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'database_service.dart';

class DataService {
  static const String _backupFileName = 'pulseassist_backup.zip';
  static const String _prefsFileName = 'shared_prefs.json';
  
  // List of all Hive boxes used in the app
  static const List<String> _boxNames = [
    'messages',
    'conversations',
    'alarms',
    'notes',
    'reminders',
    'notification_logs',
    'user_habits',
    'user_location',
  ];

  // Export Data
  static Future<void> exportData(BuildContext context, bool isTurkish) async {
    try {
      // Get SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final allPrefs = prefs.getKeys();
      final Map<String, dynamic> prefsMap = {};
      for (final key in allPrefs) {
        prefsMap[key] = prefs.get(key);
      }
      final prefsJson = jsonEncode(prefsMap);

      // Create Zip
      final encoder = ZipFileEncoder();
      final tempDir = await getTemporaryDirectory();
      final zipPath = '${tempDir.path}/$_backupFileName';
      
      encoder.create(zipPath);
      
      // Add Hive Box files
      // Make sure DB is initialized to get paths
      await DatabaseService.instance.init();
      
      for (final boxName in _boxNames) {
        try {
          // We need to ensure box is open to get property path, or use specific path knowledge
          // DatabaseService.init() opens them.
          if (Hive.isBoxOpen(boxName)) {
             final boxPath = Hive.box(boxName).path;
             if (boxPath != null) {
               final boxFile = File(boxPath);
               if (await boxFile.exists()) {
                 encoder.addFile(boxFile, '$boxName.hive');
               }
             }
          }
        } catch (e) {
          debugPrint('Error backing up box $boxName: $e');
        }
      }
      
      // Add Prefs file
      final tempPrefsFile = File('${tempDir.path}/$_prefsFileName');
      await tempPrefsFile.writeAsString(prefsJson);
      encoder.addFile(tempPrefsFile, _prefsFileName);
      
      encoder.close();

      // Share Zip
      await Share.shareXFiles(
        [XFile(zipPath)],
        subject: 'PulseAssist Data Backup',
        text: isTurkish 
          ? 'PulseAssist Yedeği - ${DateTime.now()}' 
          : 'PulseAssist Backup - ${DateTime.now()}',
      );
      
    } catch (e) {
      debugPrint('Export failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isTurkish 
              ? 'Dışa aktarma başarısız: $e' 
              : 'Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Import Data
  static Future<void> importData(BuildContext context, bool isTurkish) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result != null && result.files.single.path != null) {
        final zipFile = File(result.files.single.path!);
        final bytes = await zipFile.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        // Determine Hive Directory
        // We'll use the path of an existing box or default location
        await DatabaseService.instance.init();
        String? hivePath;
        if (Hive.isBoxOpen(_boxNames.first)) {
           hivePath = p.dirname(Hive.box(_boxNames.first).path!);
        } else {
           final appDir = await getApplicationDocumentsDirectory();
           hivePath = appDir.path;
        }

        // Validate Archive (Basic check)
        bool hasPrefs = false;
        bool hasHiveData = false;
        
        for (final file in archive) {
          if (file.name == _prefsFileName) hasPrefs = true;
          if (file.name.endsWith('.hive')) hasHiveData = true;
        }

        if (!hasPrefs && !hasHiveData) {
          throw Exception(isTurkish ? 'Geçersiz yedek dosyası' : 'Invalid backup file');
        }

        // Close Hive before Restore to release file locks
        await DatabaseService.instance.close();

        for (final file in archive) {
          if (file.isFile) {
            final data = file.content as List<int>;
            
            if (file.name == _prefsFileName) {
               // Restore Prefs
               final prefsJson = utf8.decode(data);
               final Map<String, dynamic> prefsMap = jsonDecode(prefsJson);
               final prefs = await SharedPreferences.getInstance();
               await prefs.clear();
               
               for (final entry in prefsMap.entries) {
                 final key = entry.key;
                 final value = entry.value;
                 if (value is bool) await prefs.setBool(key, value);
                 else if (value is int) await prefs.setInt(key, value);
                 else if (value is double) await prefs.setDouble(key, value);
                 else if (value is String) await prefs.setString(key, value);
                 else if (value is List) await prefs.setStringList(key, List<String>.from(value));
               }
            } else if (file.name.endsWith('.hive')) {
              // Restore Hive Box
              // file.name is like "messages.hive"
              final targetPath = p.join(hivePath!, file.name);
              final targetFile = File(targetPath);
              if (await targetFile.exists()) {
                 await targetFile.delete();
              }
              await targetFile.writeAsBytes(data);
            }
          }
        }
        
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isTurkish 
                ? 'İçe aktarma başarılı. Lütfen uygulamayı yeniden başlatın.' 
                : 'Import successful. Please restart the app.'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Import failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isTurkish 
              ? 'İçe aktarma başarısız: $e' 
              : 'Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Reset Data
  static Future<void> resetData(BuildContext context, bool isTurkish) async {
    try {
      // We must close Hive to safely delete files or use deleteBoxFromDisk
      // But deleteBoxFromDisk requires Hive to know about the box.
      // Easiest is to close, then delete the files manually or clear boxes before closing.
      
      // Strategy: Clear all boxes contents first (cleanest API usage)
      await DatabaseService.instance.init();
      
      for (final boxName in _boxNames) {
        if (Hive.isBoxOpen(boxName)) {
           await Hive.box(boxName).clear();
        } else {
           await Hive.openBox(boxName).then((box) => box.clear());
        }
      }
      
      // Also Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // Now close Hive
      await DatabaseService.instance.close();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isTurkish 
              ? 'Veriler sıfırlandı. Lütfen uygulamayı yeniden başlatın.' 
              : 'Data reset successful. Please restart the app.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('Reset failed: $e');
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isTurkish 
              ? 'Sıfırlama başarısız: $e' 
              : 'Reset failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
