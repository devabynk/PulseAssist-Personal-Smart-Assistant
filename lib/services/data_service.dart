import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'database_service.dart';

class DataService {
  static const String _backupFileName = 'pulseassist_backup.zip';
  static const String _dbName = 'smart_assistant.db';
  static const String _prefsFileName = 'shared_prefs.json';

  // Export Data
  static Future<void> exportData(BuildContext context, bool isTurkish) async {
    try {
      final dbPath = await getDatabasesPath();
      final dbFile = File(p.join(dbPath, _dbName));
      
      if (!await dbFile.exists()) {
        throw Exception(isTurkish ? 'Veritabanı bulunamadı' : 'Database not found');
      }
      
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
      
      // Add DB file
      encoder.addFile(dbFile, 'database.db');
      
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

        final dbPath = await getDatabasesPath();
        
        // Validate Archive
        bool hasDb = false;
        bool hasPrefs = false;
        
        for (final file in archive) {
          if (file.name == 'database.db') hasDb = true;
          if (file.name == _prefsFileName) hasPrefs = true;
        }

        if (!hasDb || !hasPrefs) {
          throw Exception(isTurkish ? 'Geçersiz yedek dosyası' : 'Invalid backup file');
        }

        // Close DB before Restore
        await DatabaseService.instance.close();

        for (final file in archive) {
          if (file.isFile) {
            final data = file.content as List<int>;
            if (file.name == 'database.db') {
              final targetDbPath = p.join(dbPath, _dbName);
              final targetFile = File(targetDbPath);
              if (await targetFile.exists()) {
                 await targetFile.delete();
              }
              await File(targetDbPath).writeAsBytes(data);
            } else if (file.name == _prefsFileName) {
              final prefsJson = utf8.decode(data);
              final Map<String, dynamic> prefsMap = jsonDecode(prefsJson);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              
              for (final entry in prefsMap.entries) {
                final key = entry.key;
                final value = entry.value;
                if (value is bool) {
                  await prefs.setBool(key, value);
                } else if (value is int) await prefs.setInt(key, value);
                else if (value is double) await prefs.setDouble(key, value);
                else if (value is String) await prefs.setString(key, value);
                else if (value is List) await prefs.setStringList(key, List<String>.from(value));
              }
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
      final dbPath = await getDatabasesPath();
      final dbFile = File(p.join(dbPath, _dbName));
      
      // Close DB
      await DatabaseService.instance.close();

      // Delete DB file
      if (await dbFile.exists()) {
        await dbFile.delete();
      }
      
      // Clear Prefs
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
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
